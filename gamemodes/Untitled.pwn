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

#define C_GREY 0xAFAFAFAA

//

#define SiteLink "www.orio-n.com"
//#define SiteMail "admin@d1maz.ru"
#define SiteMail "support@orio-n.com"

//

#define KickPlayer(%0) SetTimerEx("@__kick_player",250,false,"i",%0)

main(){
	print("Orio[N] RPG ("SiteLink") | copy by d1maz. (d1maz.ru)");
}

enum sr{ 
	id,
	name[MAX_PLAYER_NAME],
	email[32]
}

new user[MAX_PLAYERS][sr];

enum dlgs{
	NULL=0,
	dRegistration,
	dRegistrationEmail,
	dRegistrationVerificationEmail,
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
	SendRconCommand("weburl "SiteLink"");
	SendRconCommand("language Russian");
	SetGameModeText("Orio[N] RP/RPG v0.005r1");
	return true; 
}

public OnPlayerConnect(playerid){
	GetPlayerName(playerid,user[playerid][name],MAX_PLAYER_NAME);
	new query[37-2+MAX_PLAYER_NAME];
	mysql_format(mysql_connection,query,sizeof(query),"select`id`from`users`where`name`='%e'",user[playerid][name]);
	new Cache:cache_users=mysql_query(mysql_connection,query);
	if(cache_get_row_count(mysql_connection)){
		new string[310-2+MAX_PLAYER_NAME-2+11];
		format(string,sizeof(string),"\n\n\n\n"WHITE"Привет "BLUE"%s"WHITE"\n\nМы рады снова видеть тебя на Orio["BLUE"N"WHITE"] RPG!\nНаш адрес в интернете - "BLUE""SiteLink""WHITE"\nТвой уникальный номер аккаунта: "BLUE"%i\n"WHITE"Дата регистрации: "BLUE"11.11.1111\n\n\n\n"WHITE"Для авторизации на сервере введите пароль к аккаунту:",user[playerid][name],user[playerid][id]);
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
		user[playerid][i] = EOS;
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
				SendMail(temp_email,SiteMail,"ORION RPG","REGISTRATION",string);
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
					new temp_email[32];
					GetPVarString(playerid,"RegEmail",temp_email,sizeof(temp_email));
					user[playerid][email]=EOS;
					strmid(user[playerid][email],temp_email,0,strlen(temp_email));
					
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
	}
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

@__kick_player(playerid);
@__kick_player(playerid){
	Kick(playerid);
}