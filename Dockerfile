FROM mlikiowa/napcat-docker:latest

# 安装 Python 和 Flask（作为 FC 的 HTTP 入口）
RUN apt-get update -qq && apt-get -f install -y -qq && \
    apt-get install -y -qq python3 python3-pip && \
    pip3 install flask requests --quiet

COPY wrapper.py /wrapper.py
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
