# Identity

## Регистрация

Только в мультитенантном окружении! 
Тенанты создаются только в этом случае.

1. POST /account/register
	1.1. CATALOG: appsec.[User.CheckRegister] - ??

	1.2. CATALOG: appsec.[FindUserByPhoneNumber] - проверяет, не занят ли e-mail

	1.3. CATALOG: appsec.[CreateUser] - создает пользователя. @Tenant = -1.
		Записывает PasswordHash, SecurityStamp, EmailConfirmed = 0.
		Создает запись в таблице тенантов, устанавливает текущего пользователя Админом тенанта.

	1.4. Формируется письмо подтверждения

2. POST /account/confirmemail
	2.1. CATALOG: appsec.ConfirmEmail - просто ставит признак EmailConfirmed
	2.2. CATALOG: appsec.[FindUserById] - загружает пользователя по Id. Там есть Tenant, Locale, Segment
	2.3. SEGMENT: appsec.[CreateTenantUser] - фактически просто копия пользователя в базе сегмента

## Создание пользователя

Выполняется обработчиком A2v10.Web.Mvc.(Hooks.SimpleCreateUserHandler).
В момент создания пользователя тенант УЖЕ ИЗВЕСТЕН.

### Создание пользователя (один тенант)

Все происходит в одной БД. 

1. appsec.[User.Simple.Create] - создает пользователя
2. appsec.[UpdateUserPassword] - уснанавливает PasswordHash & SecurityStamp
3. appsec.[ConfirmEmail] - просто EmailConfirmed = 1


### Создание пользователя (мультитенант)

Все происходит в двух базах. Catalog & Segment. 

1. CATALOG: appsec.[User.Simple.Create] - создает пользователя
2. CATALOG: appsec.[UpdateUserPassword] - уснанавливает PasswordHash & SecurityStamp
3. CATALOG: appsec.[ConfirmEmail] - просто EmailConfirmed = 1
4. SEGMENT: appsec.[TenantUser.Simple.Create] - фактически просто копия пользователя в базе сегмента
