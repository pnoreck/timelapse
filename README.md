# Setup

Checkout the git in ~/timelapse and link the service and timer files in /etc/systemd/system/

  cd /etc/systemd/system/

  sudo ln -s ~/timelapse/bin/tl-capture-once.service
  sudo ln -s ~/timelapse/bin/tl-capture-once.timer
  sudo ln -s ~/timelapse/bin/tl-daily-process.service
  sudo ln -s ~/timelapse/bin/tl-daily-process.timer


Add the new services and timer

  sudo systemctl daemon-reload
  sudo systemctl enable --now tl-capture-once.timer
  sudo systemctl enable --now tl-daily-process.timer


Check if it worked and the timer are loaded

  systemctl list-timers | grep daily
  systemctl list-timers | grep capture
