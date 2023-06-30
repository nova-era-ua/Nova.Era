# Introduction 
# NovaEra
NovaEra - робоча назва перспективної вітчизняної платформи для побудови облікових систем.  
В перспективі система матиме базовий функціонал, що приблизно відповідає 1С "Торгівля і Склад" та "Управління невеликою фірмою", і дозволить програмісту-впроваджувальнику створювати власні *конфігурації* під потреби конкретного замовника аж до рівня ERP.  

Рішення на базі NovaEra - браузерні, багатокористувацькі.  
Серверна частина може бути розташована на локальному комп'ютері, на сервері в мережі або на хмарному сховищі.  
Для роботи серверної частини достатньо мати IIS + Microsoft SQL.  

Програмісту для роботи з NovaEra достатньо знати SQL + JS.

[Що нового в системі](releasenotes.md)

# Як це запустити на ПК з Windows
Для того, щоб запуститися і погратися на локальному комп'ютері з нуля, потрібно:

1. Встановити [Mіcrosoft SQL Express](https://www.microsoft.com/en-us/Download/details.aspx?id=101064) 2016 або новіший.  
Якщо ліньки розбиратися - встановлювати все по дефолту.  
Можна не встановлювати всілякі Mashine Learning Services and Language Extentions, достатньо просто сервера.  
Для зручності корисно мати під рукою ще й [SQL Server Management Studio (SSMS)](https://aka.ms/ssmsfullsetup). 

2. Створити базу даних для експериментів, наприклад з іменем neweradb.  

3. Встановити [Microsoft Visual Studio Community Edition](https://visualstudio.microsoft.com/ru/thank-you-downloading-visual-studio/?sku=Community&channel=Release&version=VS2022&source=VSLandingPage&passive=false&cid=2030).  
Встановлювати можна по мінімуму, якщо чогось не вистачить - можна буде довстановити автоматично на ходу.

4. В Visual Studio клонувати проект з https://github.com/new-era-uk/New.Era.  
Відкрити проект в Visual Studio.

5. В папці New.Era.Web знайти файл Web.config.novaera.  
Скопіювати чи перейменувати його в **Web.config**  
В четвертому рядку знайти `connectionString="Data Source=` і прописати там значання `Initial Catalog=neweradb;` (чи як там базу назвали).  
В загальному випадку  
`Data Source=СЕРВЕР\ІНСТАНС;Initial Catalog=ім'ябазиданих;`  
В восьмому рядку знайти  
`<add key="appPath" value="###full_path_for_catalog###/New.Era.App/App_application" />`  
Замість `###full_path_for_catalog###` вставити реальний шлях до папки проекту (не забути замінити слеші з `\` на `/`).

6. Виконати Build - переключити Solution Configurations на Release, зібрати проект (Build Solution, або Ctrl+Shift+B).   
В проекті з'явиться папка з SQL-скриптами.  
На своїй новоствореній базі виконати скрипт  
`\New.Era\New.Era.App\App_application\SqlScripts\application.sql`.  
Це можна зробити або з самої Visual Studio (доведеться повозитися з додатковими налаштуваннями), або з SQL Server Management Studio, що швидче і простіше.

7. Власне і все, можна тицяти на Ctrl+F5 (Run Without Debug) і дивитися на результат в браузері.  
Тестовий логін: `admin@admin.com`  
Пароль: `Admin`

***Зверніть увагу:***  
*Не забувайте оновлювати весь розробницький софт до актуальних версій.
Якщо Build проходить з помилками - спершу оновіть Visual Studio.*

Якщо не знаєте, як підступитися - перегляньте [відео в групі розбробки на Facebook](https://www.facebook.com/100026432812347/videos/3041080092873087)  

В меню Налаштування -> Розробка є можливість швидко створити тестове середовище з прикладом плану рахунків і набором базових операцій 
