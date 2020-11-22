# m05p1-ReportBugs

## Текущее состояние

        make sync       - скачать сайт  
        make build      - собрать контейнер, экспортировать (если потребуется передать в виде файла, а не через реестр)  
        make deploy     - запустить для проверки (или на удаленный сервер)
        make stop       - остановить контейнер, удалить его (также автоматически выполняется перед make deploy) 
        make all        - download and build  
        (при необходимости запускать make test вручную)

## Исходная задача

Саймон Тэтхем когда-то давно опубликовал статью «Как эффективно сообщать об ошибках». Статья решили сделать частью руководства для разработчиков. Да вот беда: разработчики трудятся над проектом, который нельзя никому показывать. К тому же, их закрыли в одном помещении без возможности ходить в интернет — у них есть только локалка, зато гигабитная и анлим. Документацию они получают в виде статических зеркал, которые запускаются на сервере в их комнате.

Та самая статья: https://www.chiark.greenend.org.uk/~sgtatham/bugs-ru.html

Ваша роль: автоматизатор.

С помощью wget необходимо делать зеркало всех языковых версий статьи, упаковывать в docker-контейнер, который будет деплоиться на местный сервер, где у разработчиков хранится документация.

Представим, что статьи обновляются раз в неделю. Нужно добавить настройку crontab, которая будет запускать обновление зеркала раз в неделю по субботам в три утра сорок пять минут.

Все операции должны быть представлены в виде Makefile, чтобы можно было запускать отдельные задачи выполнив, например, make sync — для запуска обновления зеркала, make deploy — для развертывания контейнера на целевом сервере.

Т. к. скоро вы планируете уйти в отпуск на 2 месяца, весь процесс нужно задокументировать, чтобы ваш сменщик мог без проблем поддерживать код автоматизации и дорабатывать его.

Руководствуясь принципом Everything as Code, решите поставленную задачу.

Важно: данные статьи не должны быть в репозитории.

## Makefile v1

make download - скачать сайт  
make build - собрать контейнер, экспортировать и запустить для проверки

### download - скачать все страницы

        wget -r --convert-links --no-parent --page-requisites \
            --adjust-extension --no-directories \
            --domains=www.chiark.greenend.org.uk \
            --content-on-error=on \
            --directory-prefix=$(DIR) \
            https://www.chiark.greenend.org.uk/~sgtatham/bugs-ru.html

Проблема:  
> --2020-11-21 14:04:49--  https://www.chiark.greenend.org.uk/~sgtatham/dasn@users.sf.net
> Reusing existing connection to www.chiark.greenend.org.uk:443.
> HTTP request sent, awaiting response... 404 Not Found
> 2020-11-21 14:04:49 ERROR 404: Not Found.

Это аварийно завершает этап make. Как игнорировать не нашел, --content-on-error=on не работает  
Поэтому разбил на два этапа (download и build)  
_Upd: Решено в v2_

### build - собрать контейнер

        cp $(DIR)/bugs.html $(DIR)/index.html
Файл "по умолчанию". Может быть и bugs-ru.html

        docker build --rm -f "Dockerfile" -t $(REGNAME)\$(CONTNAME):latest "."
        docker save $(REGNAME)\$(CONTNAME):latest -o $(CONTNAME).tar
        gzip -f $(CONTNAME).tar 
На случай, если нужно передать в виде файла. Либо docker push в registry

        docker ps | grep $(CONTNAME) && docker stop $(CONTNAME) || echo "Not running"
Если контейнер выполняется, остановить

        docker ps -a | grep $(CONTNAME) && docker rm $(CONTNAME) || echo "Nothing to delete"
Если контейнер существует, удалить

        docker run -d -p 8080:80 --name $(CONTNAME) $(REGNAME)\$(CONTNAME) 
Запустить для теста: (http://skf.r-as.ru:8080/)  
Последние три строчки нужны только для теста

## Dockerfile v1

        FROM nginx:1-alpine
        COPY _mirror/* /usr/share/nginx/html/

Добавить файлы зеркала в контейнер  
ENTRYPOINT стандартный

## Makefile v2

Для решения проблемы с аварийным завершением wget добавил `|| echo "Download complete"`  
Теперь echo выдает код завершения 0, и можно сделать даже make all

Разделил функционал (deploy, stop...)  

Добавил install, uninstall
        make install - добавить в cron  
        make uninstall - убрать из cron

### Особенности crontab

Для перехода в нужную директория используем ключ -C
        make -C /home/anton/SKF/m05p1-ReportBugs

Через `crontab -l` получаю текущий crontab пользователя за исключением строки, содержащей "m05p1-ReportBugs". 
И либо записываю в таком виде (для `uninstall`), либо добавив новую задачу.


Время синхронизации, команды деплоя и т.п. - все это задается в Makefile.  
