// Orion RPG by d1maz.

#include <a_samp>
#include <a_mysql>
#include <sscanf2>
#include <regex>
#include <a_http>
#define MAILER_URL "orio-n.com/mailer.php"
//#define MAILER_URL "d1maz.ru/mailer.php"
#include <mailer>

// подключение к базе данных.

#define MYSQL_HOST "localhost"
#define MYSQL_USER "root"
#define MYSQL_DATABASE "orionrpg"
#define MYSQL_PASSWORD ""
new mysql_connection;

// конфигурации.

#undef MAX_PLAYERS
#define MAX_PLAYERS 300

// цвета.

#define WHITE "{ffffff}"
#define GREEN "{249900}"
#define BLUE "{3399cc}"
#define GREY "{afafaf}"
#define RED "{fb6146}"
#define YELLOW "{ffff00}"
#define CURIOUS_BLUE "{3399cc}"
#define YELLOW_GREEN "{9acd32}"

#define C_GREY 0xAFAFAFAA
#define C_YELLOW_GREEN 0x9ACD32AA

//

#define SITE_LINK "www.orio-n.com"
//#define SITE_MAIL "admin@d1maz.ru"
#define SITE_MAIL "support@orio-n.com"
#define IP_SERVER "127.0.0.1:7777"

//

#define KickPlayer(%0) SetTimerEx("@__kick_player",250,false,"i",%0)

main(){
	print("Orio[N] RPG ("SITE_LINK") | copy by d1maz. (d1maz.ru)");
}

enum sr{ 
	id,
	name[MAX_PLAYER_NAME],
	email[32],
	gender,
	referal[MAX_PLAYER_NAME],
	character,
	money,
	bankmoney,
	dateofregister[10]
}

new user[MAX_PLAYERS][sr];

enum dlgs{
	NULL=0,
	dRegistration,
	dRegistrationEmail,
	dRegistrationVerificationEmail,
	dRegistrationReferal,
	dRegistrationGender,
	dAuthorization
}

public OnGameModeInit(){
	mysql_connection = mysql_connect(MYSQL_HOST,MYSQL_USER,MYSQL_DATABASE,MYSQL_PASSWORD);
	switch(mysql_errno(mysql_connection)){
		case 0:{
			print("сервер подключен к базе данных.");
		}
		default:{
			printf("сервер не подключен к базе данных [#%i].",mysql_errno(mysql_connection));
			return true;
		}
	}
	SendRconCommand("hostname Orio[N] RPG 2 (0.3.7) Rus/Ua");
	SendRconCommand("weburl "SITE_LINK"");
	SendRconCommand("language Russian");
	SetGameModeText("Orio[N] RP/RPG v0.010r1");
	return true; 
}

public OnPlayerConnect(playerid){
	GetPlayerName(playerid,user[playerid][name],MAX_PLAYER_NAME);
	new query[37-2+MAX_PLAYER_NAME];
	mysql_format(mysql_connection,query,sizeof(query),"select`id`from`users`where`name`='%e'",user[playerid][name]);
	new Cache:cache_users=mysql_query(mysql_connection,query);
	if(cache_get_row_count(mysql_connection)){
		new string[310-2+MAX_PLAYER_NAME-2+11];
		format(string,sizeof(string),"\n\n\n\n"WHITE"Привет "BLUE"%s"WHITE"\n\nМы рады снова видеть тебя на Orio["BLUE"N"WHITE"] RPG!\nНаш адрес в интернете - "BLUE""SITE_LINK""WHITE"\nТвой уникальный номер аккаунта: "BLUE"%i\n"WHITE"Дата регистрации: "BLUE"11.11.1111\n\n\n\n"WHITE"Для авторизации на сервере введите пароль к аккаунту:",user[playerid][name],user[playerid][id]);
		ShowPlayerDialog(playerid,dAuthorization,DIALOG_STYLE_PASSWORD,"Авторизация",string,"Войти","Отмена");
	}
	else{
		showRegistrationDialog(playerid);
	}
	cache_delete(cache_users,mysql_connection);
	return true;
}

public OnPlayerDisconnect(playerid,reason){
	for(new sr:i; i < sr; i++){
		user[playerid][i]=EOS;
	}
	return true;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[]){
	switch(dialogid){
		case dRegistration:{
			if(response){
				new temp_password[128];
				if(sscanf(inputtext,"s[128]",temp_password)){
					showRegistrationDialog(playerid);
					return true;
				}
				if(!regex_match(temp_password,"[a-zA-Z0-9]+")){
					showRegistrationDialog(playerid);
					SendClientMessage(playerid,C_GREY,""RED"x"GREY" Пароль может содержать только латинские буквы и цифры.");
                    return true;
                }
				if(strlen(temp_password) < 6 || strlen(temp_password) > 30){
					showRegistrationDialog(playerid);
					SendClientMessage(playerid,C_GREY,""RED"x"GREY" Длина пароля может быть от 6 до 30 символов.");
					return true;
				}
				SetPVarString(playerid,"RegPassword",temp_password);
				showEmailDialog(playerid);
			}
			else{
				Kick(playerid);
			}
		}
		case dRegistrationEmail:{
			if(response){
				new temp_email[128];
				if(sscanf(inputtext,"s[128]",temp_email)){
					showEmailDialog(playerid);
					return true;
				}
				if(!regex_match(temp_email,"[a-zA-Z0-9_\\.-]{1,22}+@([a-zA-Z0-9\\-]{2,8}+\\.)+[a-zA-Z]{2,4}")){
					showEmailDialog(playerid);
					SendClientMessage(playerid,C_GREY,""RED"x"GREY" Некорректный EMail!");
				    return true;
				}
				new query[42-2+32];
				mysql_format(mysql_connection,query,sizeof(query),"select`email`from`users`where`email`='%e'",temp_email);
				new Cache:cache_email=mysql_query(mysql_connection,query,true);
				if(cache_get_row_count(mysql_connection)){					
					showEmailDialog(playerid);
					SendClientMessage(playerid,C_GREY,""RED"x"GREY" Такой Email уже используется на одном из аккаунтов! Укажи другой Email.");
					return true;
				}
				cache_delete(cache_email,mysql_connection);
				new temp_code=1000+random(8999);
				SetPVarInt(playerid,"RegCode",temp_code);
				SetPVarString(playerid,"RegEmail",temp_email);
				new string[173-2+32];
				format(string,sizeof(string),""WHITE"На твой EMail "GREEN"%s"WHITE" отправлен 4-х значный код подтверждения!\nВведите его в поле ниже и нажми \"Далее\""RED"\n• Если письмо не пришло проверь папку \"Спам\"",temp_email);
				ShowPlayerDialog(playerid,dRegistrationVerificationEmail,DIALOG_STYLE_INPUT,"Подтверждение EMail",string,"Далее","");
				format(string,sizeof(string),"Привет! Для продолжения регистрации аккаунта %s введи этот код %i в окно подтверждения EMail в игре.",user[playerid][name],temp_code);
				SendMail(temp_email,SITE_MAIL,"ORION RPG","REGISTRATION",string);
			}
			else{
				Kick(playerid);
			}
		}
		case dRegistrationVerificationEmail:{
			if(response){
				new temp_code;
				if(sscanf(inputtext,"i",temp_code)){
					Kick(playerid);
					return true;
				}
				if(temp_code == GetPVarInt(playerid,"RegCode")){
					showReferalDialog(playerid);
				}
				else{
					SendClientMessage(playerid,C_GREY,""RED"x"GREY" Введён неверный код подтверждения!");
					KickPlayer(playerid);
				}
			}
			else{
				Kick(playerid);
			}
		}
		case dRegistrationReferal:{
			if(response){
				new temp_name[128];
				if(sscanf(inputtext,"s[128]",temp_name)){
					showReferalDialog(playerid);
					return true;
				}
				if(!strcmp(temp_name,user[playerid][name])){
					showReferalDialog(playerid);
					SendClientMessage(playerid,C_GREY,""RED"x"GREY" Нельзя указывать себя в качестве пригласившего!");
					return true;
				}
				new query[45-2+MAX_PLAYER_NAME];
				mysql_format(mysql_connection,query,sizeof(query),"select`id`from`users`where`name`='%e'limit 1",temp_name);
				new Cache:cache_users=mysql_query(mysql_connection,query,true);
				if(cache_get_row_count(mysql_connection)){
					SetPVarString(playerid,"RegReferal",temp_name);
					ShowPlayerDialog(playerid,dRegistrationGender,DIALOG_STYLE_MSGBOX,"Выбор пола",""WHITE"Ты Парень или Девушка?","Парень","Девушка");
				}
				else{
					showReferalDialog(playerid);
					SendClientMessage(playerid,C_GREY,""RED"x"GREY" Аккаунта с таким ником не существует!");
				}
				cache_delete(cache_users,mysql_connection);
			}
			else{
				ShowPlayerDialog(playerid,dRegistrationGender,DIALOG_STYLE_MSGBOX,"Выбор пола",""WHITE"Ты Парень или Девушка?","Парень","Девушка");
			}
		}
		case dRegistrationGender:{
			user[playerid][gender]=(response)?1:2;
			new temp_email[32],temp_password[32],temp_referal[MAX_PLAYER_NAME],temp_dateofregister[10];
			GetPVarString(playerid,"RegEmail",temp_email,sizeof(temp_email));
			strmid(user[playerid][email],temp_email,0,strlen(temp_email));
			GetPVarString(playerid,"RegPassword",temp_password,sizeof(temp_password));
			GetPVarString(playerid,"RegReferal",temp_referal,sizeof(temp_referal));
			if(!strlen(temp_referal)){
				strmid(user[playerid][referal],"-",0,1);
			}
			else{
				strmid(user[playerid][referal],temp_referal,0,1);
			}
			user[playerid][character]=(user[playerid][gender]==1)?23:192;
			user[playerid][money]=20000;
			user[playerid][bankmoney]=75000;
			new temp_day,temp_month,temp_year;
			getdate(temp_year,temp_month,temp_day);
			format(temp_dateofregister,sizeof(temp_dateofregister),"%i.%i.%i",temp_day,temp_month,temp_year);
			strmid(user[playerid][dateofregister],temp_dateofregister,0,strlen(temp_dateofregister));
			new query[136-(2*7)+MAX_PLAYER_NAME+32+32+MAX_PLAYER_NAME+1+3+10];
			mysql_format(mysql_connection,query,sizeof(query),"insert into`users`(`name`,`password`,`email`,`referal`,`gender`,`character`,`dateofregister`)values('%e','%e','%e','%e','%i','%i','%e')",user[playerid][name],temp_password,temp_email,temp_referal,user[playerid][gender],user[playerid][character],temp_dateofregister);
			new Cache:cache_users=mysql_query(mysql_connection,query,true);
			user[playerid][id]=cache_insert_id(mysql_connection);
			cache_delete(cache_users,mysql_connection);
			for(new i=0; ++i<20;){
				SendClientMessage(playerid,-1,"");
			}
			new string[83-2+32];
			format(string,sizeof(string),"IP адрес сервера: "GREEN""IP_SERVER""WHITE" | Твой пароль к аккаунту: "GREEN"%s",temp_password);
			SendClientMessage(playerid,-1,string);
			SendClientMessage(playerid,-1,"Не потеряй эти данные! Сделай снимок экрана клавишей < "CURIOUS_BLUE"F8"WHITE" >");
			SendClientMessage(playerid,-1,"Все снимки можно найти в ( "GREY"Мои документы > GTA San Andreas User Files > SAMP > Screens"WHITE" )");
			SendClientMessage(playerid,-1,"");
			SendClientMessage(playerid,-1,""GREEN"/kpk"WHITE" - поможет полноценно начать игру и узнать много нового.");
			SendClientMessage(playerid,-1,"Поздравляем с успешной регистрацией, Приятной игры!");
			SendClientMessage(playerid,-1,"");
			SendClientMessage(playerid,C_YELLOW_GREEN,"BONUS: На банковский счёт зачислено +75000$ по программе \"Бонусы для новичков\".");
			SetPVarInt(playerid,"PlayerLogged",1);
			SpawnPlayer(playerid);
		}
	}
	return true;
}

public OnPlayerSpawn(playerid){
	if(!GetPVarInt(playerid,"PlayerLogged")){
		Kick(playerid);
	}
	SetPlayerPos(playerid,-1966.1068,121.8472,27.6875);
	SetPlayerFacingAngle(playerid,90.0);
	SetPlayerSkin(playerid,user[playerid][character]);
	GivePlayerMoney(playerid,user[playerid][money]);
	return true;
}

showRegistrationDialog(playerid){
	new string[166-2+MAX_PLAYER_NAME];
	format(string,sizeof(string),""WHITE"Добро пожаловать на Orio[N] RPG!\n\n"GREEN"Никнейм - "WHITE"%s"GREEN" свободен и готов к регистрации.\n"WHITE"Придумайте пароль и введите егов поле ниже:",user[playerid][name]);
	ShowPlayerDialog(playerid,dRegistration,DIALOG_STYLE_INPUT,"Регистрация",string,"Готово","Отмена");
}

showEmailDialog(playerid){
	ShowPlayerDialog(playerid,dRegistrationEmail,DIALOG_STYLE_INPUT,"Регистрация",""WHITE"Введи действующий EMail адрес.\nЕсли ты потеряешь доступ к аккаунту, то ты сможешь восстановить его.\n"RED"• На указанный EMail придёт код подтверждения без которого нельзя продолжить регистрацию!\n"YELLOW"• Убедитесь в том, что текущий никнейм тебя устраивает, т.к. повторная регистрация с таким EMail невозможна!\n\n"WHITE"Введи Email в поле ниже и нажми \"Далее\"","Далее","Выход");
}

showReferalDialog(playerid){
	ShowPlayerDialog(playerid,dRegistrationReferal,DIALOG_STYLE_INPUT,"Регистрация",""WHITE"Если тебя кто-то пригласил на сервер, то введи его ник в поле ниже.\n"GREEN"• Когда ты достигнешь 5 уровня, пригласивший тебя игрок получит бонус.","Далее","Пропустить");
}

@__kick_player(playerid);
@__kick_player(playerid){
	Kick(playerid);
}