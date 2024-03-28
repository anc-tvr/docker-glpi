#!/bin/bash

# Контроль выбора версии или взятие последней
[[ ! "$VERSION_GLPI" ]] \
	&& VERSION_GLPI=$(curl -s https://api.github.com/repos/glpi-project/glpi/releases/latest | grep tag_name | cut -d '"' -f 4)

if [[ -z "${TIMEZONE}" ]]; then echo "Часовой пояс не установлен."; 
else 
echo "date.timezone = \"$TIMEZONE\"" > /etc/php/8.3/apache2/conf.d/timezone.ini;
echo "date.timezone = \"$TIMEZONE\"" > /etc/php/8.3/cli/conf.d/timezone.ini;
fi

# Включение session.cookie_httponly
sed -i 's,session.cookie_httponly = *\(on\|off\|true\|false\|0\|1\)\?,session.cookie_httponly = on,gi' /etc/php/8.3/apache2/php.ini

FOLDER_GLPI=glpi/
FOLDER_WEB=/var/www/html/

# Проверка, присутствует ли TLS_REQCERT
if !(grep -q "TLS_REQCERT" /etc/ldap/ldap.conf)
then
	echo "TLS_REQCERT isn't present"
	echo -e "TLS_REQCERT\tnever" >> /etc/ldap/ldap.conf
fi

# Загрузка и извлечение исходников GLPI
if [ "$(ls ${FOLDER_WEB}${FOLDER_GLPI})" ];
then
	echo "GLPI уже установлен."
else
	SRC_GLPI=$(curl -s https://api.github.com/repos/glpi-project/glpi/releases/tags/${VERSION_GLPI} | jq .assets[0].browser_download_url | tr -d \")
	TAR_GLPI=$(basename ${SRC_GLPI})

	wget -P ${FOLDER_WEB} ${SRC_GLPI}
	tar -xzf ${FOLDER_WEB}${TAR_GLPI} -C ${FOLDER_WEB}
	rm -Rf ${FOLDER_WEB}${TAR_GLPI}
	chown -R www-data:www-data ${FOLDER_WEB}${FOLDER_GLPI}
fi

# Адаптация сервера Apache в соответствии с установленной версией GLPI.
## Извлечь установленную локальную версию
LOCAL_GLPI_VERSION=$(ls ${FOLDER_WEB}/${FOLDER_GLPI}/version)
## Извлечь номер основной версии
LOCAL_GLPI_MAJOR_VERSION=$(echo $LOCAL_GLPI_VERSION | cut -d. -f1)
## Удалить точки из строки версии
LOCAL_GLPI_VERSION_NUM=${LOCAL_GLPI_VERSION//./}

## Целевое значение — GLPI 1.0.14
TARGET_GLPI_VERSION="10.0.14"
TARGET_GLPI_VERSION_NUM=${TARGET_GLPI_VERSION//./}
TARGET_GLPI_MAJOR_VERSION=$(echo $TARGET_GLPI_VERSION | cut -d. -f1)

# Сравнение числового значения номера версии с целевым номером
if [[ $LOCAL_GLPI_VERSION_NUM -lt $TARGET_GLPI_VERSION_NUM || $LOCAL_GLPI_MAJOR_VERSION -lt $TARGET_GLPI_MAJOR_VERSION ]]; then
  echo -e "<VirtualHost *:80>\n\tDocumentRoot /var/www/html/glpi\n\n\t<Directory /var/www/html/glpi>\n\t\tAllowOverride All\n\t\tOrder Allow,Deny\n\t\tAllow from all\n\t</Directory>\n\n\tErrorLog /var/log/apache2/error-glpi.log\n\tLogLevel warn\n\tCustomLog /var/log/apache2/access-glpi.log combined\n</VirtualHost>" > /etc/apache2/sites-available/000-default.conf
else
  set +H
  echo -e "<VirtualHost *:80>\n\tDocumentRoot /var/www/html/glpi/public\n\n\t<Directory /var/www/html/glpi/public>\n\t\tRequire all granted\n\t\tRewriteEngine On\n\t\tRewriteCond %{REQUEST_FILENAME} !-f\n\t\n\t\tRewriteRule ^(.*)$ index.php [QSA,L]\n\t</Directory>\n\n\tErrorLog /var/log/apache2/error-glpi.log\n\tLogLevel warn\n\tCustomLog /var/log/apache2/access-glpi.log combined\n</VirtualHost>" > /etc/apache2/sites-available/000-default.conf
fi

# Добавление запланировой задачи по cron
echo "*/2 * * * * www-data /usr/bin/php /var/www/html/glpi/front/cron.php &>/dev/null" > /etc/cron.d/glpi
# Запуск службы cron
service cron start

# Активация модуля rewrite в Apache
a2enmod rewrite && service apache2 restart && service apache2 stop

# Фикс, реально останавливающий Apache
pkill -9 apache

# Запуск службы Apache в FOREGROUND
/usr/sbin/apache2ctl -D FOREGROUND
