FROM mlikiowa/napcat-docker:latest

RUN cp /app/entrypoint.sh /app/napcat-entrypoint.sh && \
    cd /app && unzip -q NapCat.Shell.zip -d /app/napcat 2>/dev/null || true

RUN apt-get update -qq && apt-get -f install -y -qq && \
    apt-get install -y -qq python3 python3-pip && \
    pip3 install flask requests --quiet

COPY wrapper.py /wrapper.py
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
