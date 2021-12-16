package main

import (
	"bufio"
	"encoding/csv"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"sort"
	"strings"
	"sync"
)

type Block struct {
	Category   string
	Ticktype   string
	SourceRepo string
	URL        string
}

func run() error {
	resp, err := http.Get("https://v.firebog.net/hosts/csv.txt")
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	r := csv.NewReader(resp.Body)
	r.Comma = ','
	rows, err := r.ReadAll()
	if err != nil {
		return err
	}

	blocklist := make([]Block, 0, len(rows))
	for _, row := range rows {
		if len(row) < 5 {
			return fmt.Errorf("failed to parse row:'%v'", row)
		}

		block := Block{
			Category:   row[0],
			Ticktype:   row[1],
			SourceRepo: row[2],
			URL:        row[4],
		}

		switch block.Category {
		case "suspicious", "tracking", "malicious", "other":
		case "advertising":
		default:
			log.Println("unknown category ", block.Category)
			continue
		}

		switch block.Ticktype {
		case "tick":
			// allow all ticked
		case "std":
			// allow some repos from std's
			switch {
			case strings.HasPrefix(block.SourceRepo, "https://someonewhocares.org"):
			// suspicious
			case strings.HasPrefix(block.SourceRepo, "https://github.com/Perflyst/PiHoleBlocklist"):
				// tracking, Android Trackers, SmartTV domain Trackers
			default:
				continue
			}
		default:
			// drop others that may have too many false positives
			continue
		}

		blocklist = append(blocklist, block)
	}

	// get all blocklists in parallel
	var (
		wg sync.WaitGroup
		ch = make(chan []string)
	)
	for _, block := range blocklist {
		wg.Add(1)
		go func(block Block) {
			defer wg.Done()

			// retries
			for i := 0; i < 3; i++ {
				log.Println("Downloading hosts:", block)

				// get list
				resp, err := http.Get(block.URL)
				if err != nil {
					log.Println(err)
					continue
				}
				defer resp.Body.Close()

				// parse hosts from list
				var (
					hosts = make([]string, 0, 1024)
					re    = strings.NewReplacer(
						// ipv4 localhost
						"0.0.0.0", "",
						"127.0.0.1", "",
						"255.255.255.255", "",

						// ipv6 localhost
						"::1", "",
						"fe00::0", "",
						"fe00::1", "",
						"fe00::2", "",
						"fe00::3", "",
						"::", "",
					)
				)
				r := bufio.NewScanner(resp.Body)
				for r.Scan() {
					host := r.Text()

					// replace IPs
					host = re.Replace(host)
					host = strings.TrimSpace(host)

					// drop comments
					if strings.HasPrefix(host, "#") {
						continue
					}

					// drop empty lines
					if len(host) == 0 {
						continue
					}
					hosts = append(hosts, host)
				}

				if r.Err() != nil {
					log.Println(r.Err())
					return
				}

				ch <- hosts
			}
		}(block)
	}

	// close chan after processing
	go func() {
		wg.Wait()
		close(ch)
	}()

	// list of domains to be blocked, make them unique
	hostslist := make(map[string]struct{})
	for hosts := range ch {
		for _, host := range hosts {
			hostslist[host] = struct{}{}
		}
	}

	// sort
	hosts := make([]string, 0, len(hostslist))
	for host := range hostslist {
		hosts = append(hosts, host)
	}
	sort.Strings(hosts)

	// print to stdout
	for _, host := range hosts {
		fmt.Fprintf(os.Stdout, "0.0.0.0 %s\n", host)
	}
	return nil
}

func main() {
	log.SetOutput(io.Discard)
	if err := run(); err != nil {
		log.Fatal(err)
	}
}
