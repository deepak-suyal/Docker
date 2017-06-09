FROM ubuntu:latest

ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

# Update the repositories
RUN apt-get -yqq update

# Upgrade packages
RUN apt-get -yqq upgrade

# Set the locale
RUN apt-get clean && apt-get update
RUN apt-get install locales
RUN locale-gen en_US.UTF-8

# Set timezone
ENV TZ "US/Eastern"
RUN echo "US/Eastern" | tee /etc/timezone
RUN apt-get update && apt-get install tzdata
RUN dpkg-reconfigure --frontend noninteractive tzdata

# Install utilities
RUN apt-get -yqq install ca-certificates curl dnsutils man openssl unzip wget

# Install xvfb and fonts
RUN apt-get -yqq install xvfb fonts-ipafont-gothic xfonts-100dpi xfonts-75dpi xfonts-scalable xfonts-cyrillic

# Install Fluxbox (window manager)
RUN apt-get -yqq install fluxbox
 
# Install VNC
RUN apt-get -yqq install x11vnc
RUN mkdir -p ~/.vnc

# Install Supervisor
RUN apt-get -yqq install supervisor
RUN mkdir -p /var/log/supervisor

# Install Java
RUN apt-get -yqq install openjdk-8-jre-headless

# Install Selenium
RUN mkdir -p /opt/selenium
RUN wget --no-verbose -O /opt/selenium/selenium-server-standalone-3.4.0.jar http://selenium-release.storage.googleapis.com/3.4/selenium-server-standalone-3.4.0.jar
RUN ln -fs /opt/selenium/selenium-server-standalone-3.4.0.jar /opt/selenium/selenium-server-standalone.jar

# Install Chrome WebDriver
RUN wget --no-verbose -O /tmp/chromedriver_linux64.zip http://chromedriver.storage.googleapis.com/2.9/chromedriver_linux64.zip
RUN mkdir -p /opt/chromedriver-2.9
RUN unzip /tmp/chromedriver_linux64.zip -d /opt/chromedriver-2.9
RUN chmod +x /opt/chromedriver-2.9/chromedrive
RUN rm /tmp/chromedriver_linux64.zip
RUN ln -fs /opt/chromedriver-2.9/chromedriver /usr/local/bin/chromedriver

# Install Google Chrome
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
RUN echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list
RUN apt-get -yqq update
RUN apt-get -yqq install google-chrome-stable

# Install Firefox
RUN apt-get -yqq install firefox

# Install geckodriver
RUN wget https://github.com/mozilla/geckodriver/releases/download/v0.13.0/geckodriver-v0.13.0-linux64.tar.gz
RUN tar -xvzf geckodriver*
RUN chmod +x geckodriver
RUN mv geckodriver /usr/local/bin/

# Configure Supervisor 
ADD ./etc/supervisor/conf.d /etc/supervisor/conf.d

# Configure VNC Password
RUN x11vnc -storepasswd selenium ~/.vnc/passwd

# Create a default user with sudo access
RUN useradd selenium --shell /bin/bash --create-home
RUN usermod -a -G sudo selenium
RUN echo "ALL ALL = (ALL) NOPASSWD: ALL" >> /etc/sudoers

# Default configuration
ENV SCREEN_GEOMETRY "1440x900x24"
ENV SELENIUM_PORT 4444
ENV DISPLAY :20.0

# Disable the SUID sandbox so that Chrome can launch without being in a privileged container.
# One unfortunate side effect is that `google-chrome --help` will no longer work.
RUN dpkg-divert --add --rename --divert /opt/google/chrome/google-chrome.real /opt/google/chrome/google-chrome
RUN echo "#!/bin/bash\nexec /opt/google/chrome/google-chrome.real --disable-setuid-sandbox \"\$@\"" > /opt/google/chrome/google-chrome
RUN chmod 755 /opt/google/chrome/google-chrome

# Ports
EXPOSE 4444 5900

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
