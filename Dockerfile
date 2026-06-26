ARG VERSAO_ERP=v15
FROM frappe/erpnext:${VERSAO_ERP}

USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    default-mysql-client \
    redis-tools \
    && rm -rf /var/lib/apt/lists/*

USER frappe

RUN bench get-app healthcare https://github.com/earthians/marley --branch v15.1.20

USER root
COPY entrypoint.sh /home/frappe/entrypoint.sh
RUN chown frappe:frappe /home/frappe/entrypoint.sh && chmod +x /home/frappe/entrypoint.sh
USER frappe

ENTRYPOINT ["/home/frappe/entrypoint.sh"]
