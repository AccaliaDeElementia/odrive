# I'd rather use alpine, but i get a file not found error if i do.... most annoying
FROM ubuntu

WORKDIR /app
ADD  . /app
VOLUME /data
VOLUME /home/odrive/.odrive-agent

RUN apt-get update \
    && \
    apt-get install -y -q --no-install-recommends \
       curl ca-certificates \
    && \
    apt-get clean \
    && \
    groupadd -g 1000 odrive \
    && \
    useradd -d /home/odrive -g 1000 -m -u 1000 odrive \
    && \
    touch \
        /var/log/odriveagent.log \
        /var/log/odriveagent.1.log \
        /var/log/odrivesync.log \
        /var/log/odrivesync.1.log \
        /var/log/odriverefresh.log \
        /var/log/odriverefresh.1.log \
        /app/run.pids \
    && \
    chown odrive:odrive /app /app/* /var/log/odrive* \
    && \
    chmod ug+rwX /app /app/* /var/log/odrive*
    
USER odrive

RUN curl -L "http://dl.odrive.com/odrive-py" --create-dirs -o "/app/bin/odrive.py" \
    && \
    curl -L "http://dl.odrive.com/odriveagent-lnx-64" | tar -xvzf- -C "/app/bin/" \
    && \
    curl -L "http://dl.odrive.com/odrivecli-lnx-64" | tar -xvzf- -C "/app/bin/" \
    && \
    chmod +x /app/bin/*

ENV ODRIVE_AUTH_TOKEN=NOAUTH
ENV ODRIVE_REMOTE_MOUNT="/"

CMD ["/bin/bash", "/app/runodrive.sh"]
HEALTHCHECK CMD ["/bin/bash", "/app/healthcheck.sh"]
  