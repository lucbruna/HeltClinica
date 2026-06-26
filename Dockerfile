ARG VERSAO_ERP=v15
FROM frappe/erpnext:${VERSAO_ERP}

USER frappe
RUN bench get-app healthcare https://github.com/earthians/marley --branch v15.1.20
