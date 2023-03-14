rule_t14 = {
  matches = {
    {
      { "device.name", "equals", "alsa_card.pci-0000_07_00.6" },
    },
  },
  apply_properties = {
    ["device.description"] = "T14",
  },
}

rule_t14_hdmi = {
  matches = {
    {
      { "device.name", "equals", "alsa_card.pci-0000_07_00.1" },
    },
  },
  apply_properties = {
    ["device.description"] = "T14 HDMI",
    ["device.profile.name"] = "off",
  },
}

rule_dock = {
  matches = {
    {
      { "device.name", "equals", "alsa_card.usb-Lenovo_ThinkPad_Thunderbolt_3_Dock_USB_Audio_000000000000-00" },
    },
  },
  apply_properties = {
    ["device.description"] = "Dock",
    ["device.profile.name"] = "off",
  },
}

table.insert(alsa_monitor.rules, rule_t14)
table.insert(alsa_monitor.rules, rule_t14_hdmi)
table.insert(alsa_monitor.rules, rule_dock)
