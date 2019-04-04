// Orion RPG by d1maz.

#include <a_samp>
#include <a_mysql>

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

//

#define SiteLink "www.orio-n.com"

main(){
	print("Orio[N] RPG ("SiteLink") | copy by d1maz. (d1maz.ru)");
}

enum sr{ 
	id,
	name[MAX_PLAYER_NAME],
}

new user[MAX_PLAYERS][sr];

enum dlgs{
	NULL=0,
	dRegistration,
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
	SetGameModeText("Orio[N] RP/RPG v0.003r1");
	return true; 
}

new bool:playerlogged[MAX_PLAYERS];

public OnPlayerConnect(playerid){
	if(playerlogged[playerid] == true){
		
	}
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
		new string[166-2+MAX_PLAYER_NAME];
		format(string,sizeof(string),""WHITE"Добро пожаловать на Orio[N] RPG!\n\n"GREEN"Никнейм - "WHITE"%s"GREEN" свободен и готов к регистрации.\n"WHITE"Придумайте пароль и введите егов поле ниже:",user[playerid][name]);
		ShowPlayerDialog(playerid,dRegistration,DIALOG_STYLE_INPUT,"Регистрация",string,"Готово","Отмена");
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