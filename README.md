# Introduction 

[Що нового в системі](releasenotes.md)

# Як це запустити
Для того, щоб запуститися і погратися на локальному комп'ютері з Windows з нуля, потрібно:

1. Встановити **Mіcrosoft SQL Express** не старіший за 2016 
(https://www.microsoft.com/en-us/Download/details.aspx?id=101064)  
Якщо ліньки розбиратися - встановлювати все по дефолту.  
Можна не встановлювати всякі Mashine Learning Services and Language Extentions, достатньо просто сервера.  
Для зручності корисно мати ще й **SQL Server Management Studio** (SSMS)
(https://aka.ms/ssmsfullsetup). 

2. Створити базу даних для експериментів, наприклад і іменем neweradb.  

3. Встановити **Microsoft Visual Studio Community Edition**
https://visualstudio.microsoft.com/ru/thank-you-downloading-visual-studio/?sku=Community&channel=Release&version=VS2022&source=VSLandingPage&passive=false&cid=2030  
Можна по мінімуму, якщо чого не вистачить - можна буде довстановити автоматично на ходу.

4. В Visual Studio клонувати проект з https://github.com/new-era-uk/New.Era  
Відкрити проект в Visual Studio.

5. В папці New.Era.Web знайти файл Web.config.newera  
Скопіювати чи перейменувати в **Web.config**  
В четвертому рядку знайти `connectionString="Data Source=` і прописати там значання `Initial Catalog=neweradb;` (чи як там базу назвали).  
В загальному випадку  
`Data Source=СЕРВЕР\ІНСТАНС;Initial Catalog=ім'ябазиданих;`  
В восьмому рядку знайти  
`<add key="appPath" value="###full_path_for_catalog###/New.Era.App/App_application" />`  
Замість `###full_path_for_catalog###` вставили реальний шлях до папки проекту (не забути замінити слеші з `\` на `/`).

6. На своїй новоствореній базі виконати два скрипта:  
спочатку `\New.Era\New.Era.App\App_application\@sql\platform\a2v10platform.sql`  
потім `\New.Era\New.Era.App\App_application\SqlScripts\application.sql`  
Або з самої Visual Studio, або з SQL Server Management Studio (швидче), обов'язково в наведеному порядку.  

7. Все, можна тицяти в Visual Studio Ctrl+F5 (Run Without Debug) і дивитися на результат в браузері.

# Build and Test
TODO: Describe and show how to build your code and run the tests. 

# Contribute
TODO: Explain how other users and developers can contribute to make your code better. 

- 