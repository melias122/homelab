{
  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput = {
    enable = true;
    touchpad = {
      naturalScrolling = true;
      tapping = false;
      disableWhileTyping = true;
    };
  };
}
