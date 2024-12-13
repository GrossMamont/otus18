#!/bin/bash

#Подготовим ОС
echo "Настроим ОС"
yum install -y epel-release
yum install -y nginx
echo "Установим необходимые пакеты"
yum install -y setroubleshoot-server selinux-policy-mls setools-console policycoreutils-python-utils policycoreutils-newrole
echo "Подправим конфиг nginx'а"
sed -ie 's/:80/:4881/g' /etc/nginx/nginx.conf
sed -i 's/listen       80;/listen       4881;/' /etc/nginx/nginx.conf
echo "Запустим nginx и посмотрим статус"
systemctl start nginx
systemctl status nginx
echo "Глянем, висит ли чего на нужном порту?"
ss -tlpn | grep 4881
echo "nginx не работает и порт не занят"


echo "проверим, что в ОС отключен файервол"
systemctl status firewalld
echo "можно проверить, что конфигурация nginx настроена без ошибок"
nginx -t
echo "проверим режим работы SELinux"
getenforce

#Разрешим в SELinux работу nginx на порту TCP 4881 c помощью переключателей setsebool
echo "1. Разрешим в SELinux работу nginx на порту TCP 4881 c помощью переключателей setsebool"

echo "Находим в логах информацию о блокировании порта"
grep src=4881 /var/log/audit/audit.log | audit2why
echo "Включим параметр nis_enabled и перезапустим nginx"
setsebool -P nis_enabled on
systemctl restart nginx
systemctl status nginx
echo "Проверить статус параметра можно с помощью команды"
getsebool -a | grep nis_enabled
echo "отключим nis_enabled"
setsebool -P nis_enabled off

#Теперь разрешим в SELinux работу nginx на порту TCP 4881 c помощью добавления нестандартного порта в имеющийся тип
echo "2. Теперь разрешим в SELinux работу nginx на порту TCP 4881 c помощью добавления нестандартного порта в имеющийся тип"
echo "Поиск имеющегося типа, для http трафика"
semanage port -l | grep http
echo "Добавим порт в тип http_port_t"
semanage port -a -t http_port_t -p tcp 4881
semanage port -l | grep  http_port_t
echo "перезапускаем службу nginx и проверим её работу"
systemctl restart nginx
systemctl status nginx
echo "Удалим нестандартный порт из имеющегося типа"
semanage port -d -t http_port_t -p tcp 4881
semanage port -l | grep  http_port_t
echo "перезапускаем службу nginx и проверим её работу"
systemctl restart nginx
systemctl status nginx

#Разрешим в SELinux работу nginx на порту TCP 4881 c помощью формирования и установки модуля SELinux
echo "3. Разрешим в SELinux работу nginx на порту TCP 4881 c помощью формирования и установки модуля SELinux"
echo "Попробуем снова запустить Nginx"
systemctl start nginx
echo "Посмотрим логи SELinux, которые относятся к Nginx"
grep nginx /var/log/audit/audit.log
echo "сделаем модуль, разрешающий работу nginx на нестандартном порту"
grep nginx /var/log/audit/audit.log | audit2allow -M nginx
echo "применяем данный модуль"
semodule -i nginx.pp
echo "перезапускаем службу nginx и проверим её работу"
systemctl restart nginx
systemctl status nginx
echo "Просмотр всех установленных модулей"
semodule -l
echo "Для удаления модуля воспользуемся командой"
semodule -r nginx
echo "Поиск"
echo "Поиск"
