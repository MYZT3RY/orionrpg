#include <a_samp>
#include <a_mysql>

// подключение к базе данных.

#define MYSQL_HOST "localhost"
#define MYSQL_USER "root"
#define MYSQL_DATABASE "orionrpg"
#define MYSQL_PASSWORD ""
new mysql_connection;

main(){
	print("Orio[N] RPG | copy by d1maz.");
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
	SendRconCommand("hostname Orio[N] RPG 2 (0.3.7) Rus/Ua ");
	SendRconCommand("weburl orio-n.com");
	SendRconCommand("language Russian");
	SetGameModeText("Orio[N] RP/RPG");
	return true; 
}