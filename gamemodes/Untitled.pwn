// Orion RPG by d1maz. - vk.com/d1maz.community

#include <a_samp>
#include <a_mysql>
#include <sscanf2>
#include <regex>
#include <a_http>
#define MAILER_URL "orio-n.com/mailer.php"
//#define MAILER_URL "d1maz.ru/mailer.php"
#include <mailer>
#include <streamer>
#include <additions/pickups>
#include <additions/3dtexts>
#include <additions/colors>
#include <additions/configuration>
#include <dc_cmd>

// подключение к базе данных.

#define MYSQL_HOST "localhost"
#define MYSQL_USER "root"
#define MYSQL_DATABASE "orionrpg"
#define MYSQL_PASSWORD ""
new mysql_connection;

//

#define KickPlayer(%0) SetTimerEx("kick_player",250,false,"i",%0)

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
	dateofregister[10],
	licenses[MAX_LICENSES],
	changerespawn
}

new user[MAX_PLAYERS][sr];

enum dlgs{
	NULL=0,
	dRegistration,
	dRegistrationEmail,
	dRegistrationVerificationEmail,
	dRegistrationReferal,
	dRegistrationGender,
	dAuthorization,
	dAuthorizationRestore,
	dAuthorizationRestoreCode,
	dHelp,
	dHelpAddition,
	dLastPos,
	dBuyLicenses
}

// переменные

new infoAboutLicenses[][]={{120000,2},{200000,3},{50000,1},{100000,2}};

//

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
	DisableInteriorEnterExits();
	Create3DTexts();
	CreatePickups();
	SendRconCommand("hostname Orio[N] RPG 2 (0.3.7) Rus/Ua");
	SendRconCommand("weburl "SITE_LINK"");
	SendRconCommand("language Russian");
	SetGameModeText("Orio[N] RP/RPG v0.023r1");
	return true; 
}

public OnPlayerConnect(playerid){
	GetPlayerName(playerid,user[playerid][name],MAX_PLAYER_NAME);
	return true;
}

public OnPlayerRequestClass(playerid,classid){
	new query[55-2+MAX_PLAYER_NAME];
	mysql_format(mysql_connection,query,sizeof(query),"select`id`,`dateofregister`from`users`where`name`='%e'",user[playerid][name]);	
	new Cache:cache_users=mysql_query(mysql_connection,query);
	if(cache_get_row_count(mysql_connection)){
		user[playerid][id]=cache_get_field_content_int(0,"id",mysql_connection);
		cache_get_field_content(0,"dateofregister",user[playerid][dateofregister],mysql_connection,10);
		showAuthorizationDialog(playerid);
	}
	else{
		showRegistrationDialog(playerid);
	}
	cache_delete(cache_users,mysql_connection);
	return true;
}

public OnPlayerDisconnect(playerid,reason){
	if(GetPVarInt(playerid,"PlayerLogged")){
		new Float:temp_x,Float:temp_y,Float:temp_z,Float:temp_fa,temp_interior,temp_virtualworld;
		GetPlayerPos(playerid,temp_x,temp_y,temp_z);
		GetPlayerFacingAngle(playerid,temp_fa);
		temp_interior=GetPlayerInterior(playerid);
		temp_virtualworld=GetPlayerVirtualWorld(playerid);
		new query[60-2-2+50+11];
		mysql_format(mysql_connection,query,sizeof(query),"update`users`set`lastpos`='%f|%f|%f|%f|%i|%i'where`id`='%i'",temp_x,temp_y,temp_z,temp_fa,temp_interior,temp_virtualworld,user[playerid][id]);
		mysql_query(mysql_connection,query,false);
	}
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
		case dAuthorization:{
			if(response){
				new temp_password[128];
				if(sscanf(inputtext,"s[128]",temp_password)){
					showAuthorizationDialog(playerid);
					return true;
				}
				new query[53-2-2+MAX_PLAYER_NAME+32];
				mysql_format(mysql_connection,query,sizeof(query),"select*from`users`where`name`='%e'and`password`='%e'",user[playerid][name],temp_password);				
				new Cache:cache_users=mysql_query(mysql_connection,query,true);
				if(cache_get_row_count(mysql_connection)){
					loadUser(playerid,cache_users);
					SetPVarInt(playerid,"PlayerLogged",1);
					SpawnPlayer(playerid);
				}
				else{
					SetPVarInt(playerid,"loginAttemps",GetPVarInt(playerid,"loginAttemps")+1);
					if(GetPVarInt(playerid,"loginAttemps")==3){
						showRestoreUserDialog(playerid);
					}
					else{
						showAuthorizationDialog(playerid);
						new string[64-2+1];
						format(string,sizeof(string),"Введен неверный пароль! У тебя осталось %i попыток ввода пароля",3-GetPVarInt(playerid,"loginAttemps"));
						SendClientMessage(playerid,C_RED,string);
					}
				}
				cache_delete(cache_users,mysql_connection);
			}
			else{
				Kick(playerid);
			}
		}
		case dAuthorizationRestore:{
			if(response){
				new temp_email[128];
				if(sscanf(inputtext,"s[128]",temp_email)){
					showRestoreUserDialog(playerid);
					return true;
				}
				if(!regex_match(temp_email,"[a-zA-Z0-9_\\.-]{1,22}+@([a-zA-Z0-9\\-]{2,8}+\\.)+[a-zA-Z]{2,4}")){
					showRestoreUserDialog(playerid);
					SendClientMessage(playerid,C_GREY,""RED"x"GREY" Некорректный EMail!");
				    return true;
				}
				new query[66-2-2+30+32];
				mysql_format(mysql_connection,query,sizeof(query),"select`password`from`users`where`name`='%e'and`email`='%e'limit 1",user[playerid][name],temp_email);				
				new Cache:cache_users=mysql_query(mysql_connection,query,true);
				if(cache_get_row_count(mysql_connection)){
					new temp_code=10000000+random(89999999);
					SetPVarInt(playerid,"RestoreCode",temp_code);
					SetPVarString(playerid,"RestoreEmail",temp_email);
					new string[159-2-2+MAX_PLAYER_NAME+8];
					format(string,sizeof(string),"Привет! Для восстановления доступа к аккаунту %s введи этот код %i в игре. Если ты не делал(а) запрос на восстановление, то просто проигнорируй это сообщение!",user[playerid][name],temp_code);					
					SendMail(temp_email,SITE_MAIL,"ORION RPG","PASSWORD",string);
					showRestoreUserCodeDialog(playerid);
				}
				else{
					KickPlayer(playerid);
				}
				cache_delete(cache_users,mysql_connection);
			}
			else{
				Kick(playerid);
			}
		}
		case dAuthorizationRestoreCode:{
			if(response){
				new temp_code;
				if(sscanf(inputtext,"i",temp_code)){
					showRestoreUserCodeDialog(playerid);
					return true;
				}
				if(temp_code==GetPVarInt(playerid,"RestoreCode")){
					new temp_email[32];
					GetPVarString(playerid,"RestoreEmail",temp_email,sizeof(temp_email));
					new query[66-2-2+MAX_PLAYER_NAME+32];
					mysql_format(mysql_connection,query,sizeof(query),"select`password`from`users`where`name`='%e'and`email`='%e'limit 1",user[playerid][name],temp_email);					
					new Cache:cache_users=mysql_query(mysql_connection,query,true);
					new temp_password[32];
					cache_get_field_content(0,"password",temp_password,mysql_connection,sizeof(temp_password));
					cache_delete(cache_users,mysql_connection);
					new string[39-2+32];
					format(string,sizeof(string),""WHITE"Пароль от аккаунта: "GREEN"%s",temp_password);					
					ShowPlayerDialog(playerid,0,DIALOG_STYLE_MSGBOX,"Пароль",string,"Выход","");
					KickPlayer(playerid);
				}
				else{
					Kick(playerid);
				}
			}
			else{
				Kick(playerid);
			}
		}
		case dHelp:{
			if(response){
				static string[1169];
				switch(listitem){
					case 0:{
						strcat(string,"\n\n\n\nДля ввода команд используй клавишу "WHITE"F6"LIGHT_STEEL_BLUE" или "WHITE"T"LIGHT_STEEL_BLUE"(на латинице)\n");
						strcat(string,"Пример: Попробуй достать свой карманный компьютер. Нажми "WHITE"F6"LIGHT_STEEL_BLUE" и введи в окошко "WHITE"/kpk.\n");
						strcat(string,"\n"LIGHT_STEEL_BLUE"Так же, ты можешь разговаривать с другими игроками пользуясь чатом.\n");
						strcat(string,"Есть несколько видов чата: "WHITE"/o"LIGHT_STEEL_BLUE" - общий чат, "WHITE"/c"LIGHT_STEEL_BLUE" - ближний чат, "WHITE"/s"LIGHT_STEEL_BLUE" - чат с высоким радиусом(Крик).\n");
						strcat(string,"Пример: Нажми "WHITE"F6"LIGHT_STEEL_BLUE" и введи в окошко "WHITE"/s привет"LIGHT_STEEL_BLUE".\n");
						strcat(string,"Этот чат позволит привлечь больше внимания и тебя услышат на большом расстоянии.\n\n\n");
					}
					case 1:{
						strcat(string,"\n\n\n\nУровень игрока"WHITE"(LvL в правом верхнем углу экрана)"LIGHT_STEEL_BLUE" является главным ключём к новым возможностям.\n");
						strcat(string,"Например: с 1-го уровня можно общаться с игроками в общем чате и получить лицензию на мототранспорт, со 2-го попасть в Организацию или Банду, с 3-го получить лицензию на ношение оружия, и т.д.\n");
						strcat(string,"В правом верхнем углу экрана отображается "WHITE"LvL"LIGHT_STEEL_BLUE" и "WHITE"Exp"LIGHT_STEEL_BLUE" персонажа. "WHITE"1 Exp = 1 час игры на сервере"LIGHT_STEEL_BLUE", т.е."WHITE" для получения 1-го уровня тебе необходимо получить 4 Exp"LIGHT_STEEL_BLUE".\n");
						strcat(string,"Чем выше уровень, тем больше Exp необходимо получить.\n");
						strcat(string,"На сервере присутствует "WHITE"система VIP-аккаунтов"LIGHT_STEEL_BLUE". Всего 3 вида VIP. Игрок достигший 15 уровня автоматически становится VIP игроком сервера и получает дополнительные возможности.\n\n\n");
					}
					case 2:{
						strcat(string,"\n\n\n\nНа сервере ведут активную деятельность различные фракции.\n");
						strcat(string,"Банды занимаются разбойными нападениями, торгуют оружием и наркотиками.\n");
						strcat(string,"Стражи порядка(Законники) стараются перекрыть кислород мафиям и бандам.\n");
						strcat(string,"Наёмники разглядывают свою жертву в снайперском прицеле.\n");
						strcat(string,"Медики спешат на вызов после очередной перестрелки.\n\n");
						strcat(string,"На сервере "WHITE"8 организаций"LIGHT_STEEL_BLUE", "WHITE"4 мафии"LIGHT_STEEL_BLUE" и "WHITE"9 банд"LIGHT_STEEL_BLUE".\n");
						strcat(string,"В каждой фракции есть глава"WHITE"(Лидер)"LIGHT_STEEL_BLUE". Только лидер может принять новобранца во фракцию"WHITE" (Для вступления необходим 2 уровень)"LIGHT_STEEL_BLUE".\n");
						strcat(string,"У каждой фракции есть свой личный раздел на форуме "WHITE""SITE_LINK""LIGHT_STEEL_BLUE". В разделе лидер публикует необходимую информацию для своей фракции.\n\n");
						strcat(string,"Список фракций:\n\n");
						strcat(string,""WHITE"Организации: "LIGHT_STEEL_BLUE"Полиция Los Santos, Полиция Las Venturas, FBI, Армия, Такси, Агенство новостей, Наёмники, МЧС.\n");
						strcat(string,""WHITE"Банды: "LIGHT_STEEL_BLUE"East Side Ballas, Grove Street, El Coronos, LS Vagos, LS Convers, SF Rifa, Байкеры, Street Racers LS, Street Racers LV\n");
						strcat(string,""WHITE"Мафии: "LIGHT_STEEL_BLUE"Yakuza, Triads, Русская мафия, La Cosa Nostra\n\n\n");
					}
					case 3:{
						strcat(string,"\n\n\n\nНа сервере имеется различная недвижимость.\n");
						strcat(string,""WHITE"Дома"LIGHT_STEEL_BLUE","WHITE" Магазины незаконной продукции(МНП)"LIGHT_STEEL_BLUE", "WHITE"Автомобильные Заправочные Станции(АЗС)"LIGHT_STEEL_BLUE".\n");
						strcat(string,"Купить недвижимость может любой игрок достигший 5 или выше уровня и имеющий финансовый бюджет для этого.\n");
						strcat(string,"Быть владельцем ресторана, оружейного магазина или автосалона...\n");
						strcat(string,"Жить в особняке в самом престижном районе "WHITE"VineWood"LIGHT_STEEL_BLUE" - это осуществимые желания.\n\n\n");
					}
					case 4:{
						strcat(string,"\n\n\n\nОгромное кол-во мест трудоустройства помогут зарабатывать начальный капитал.\n");
						strcat(string,"Грузчик, Дальнобойщик, Продавец лотерейных билетов, Уборщик мусора.. это лишь небольшой список работ доступных на сервере.\n");
						strcat(string,"Но для любой работы необходимо сначала получить "WHITE"водительские права"LIGHT_STEEL_BLUE".\n");
						strcat(string,"Найти автошколу или желаемое место работы поможет "WHITE"GPS-навигатор"LIGHT_STEEL_BLUE" в твоём "WHITE"/kpk"LIGHT_STEEL_BLUE".\n\n\n");
					}
					case 5:{
						strcat(string,"\n\n\n\nНа сервере огромный функционал и большое кол-во возможностей.\n");
						strcat(string,"На нашем форуме "WHITE""SITE_LINK""LIGHT_STEEL_BLUE" в разделе "WHITE"F.A.Q."LIGHT_STEEL_BLUE" ты можешь найти много полезной информации для себя и узнать много нового.\n");
						strcat(string,"Если тебе что-то не понятно по игровому процессу, то ты всегда можешь обратиться к "WHITE"помошникам(Хелперам)"LIGHT_STEEL_BLUE" сервера.\n");
						strcat(string,"Задай им свой вопрос. Нажми клавишу "WHITE"F6"LIGHT_STEEL_BLUE" и в окошко введи команду "WHITE"/ask [текст вопроса]"LIGHT_STEEL_BLUE".\n\n\n");
					}
				}
				ShowPlayerDialog(playerid,dHelpAddition,DIALOG_STYLE_MSGBOX,"Помощь",string,"Назад","Назад");
				string="";
			}
		}
		case dHelpAddition:{
			if(response || !response){
				ShowPlayerDialog(playerid,dHelp,DIALOG_STYLE_LIST,"Помощь","Команды и чат.\nУровень.\nФракции.\nНедвижимость.\nРаботы.\nБолее подробная информация.","Читать","Выйти");
			}
		}
		case dLastPos:{
			if(response){
				if(GetPVarFloat(playerid,"LastPosX")){
					SetPlayerPos(playerid,GetPVarFloat(playerid,"LastPosX"),GetPVarFloat(playerid,"LastPosY"),GetPVarFloat(playerid,"LastPosZ"));
					SetPlayerFacingAngle(playerid,GetPVarFloat(playerid,"LastPosFA"));
					SetPlayerInterior(playerid,GetPVarInt(playerid,"LastPosInterior"));
					SetPlayerVirtualWorld(playerid,GetPVarInt(playerid,"LastPosVirtualWorld"));
					new temp_command[41-2+9];
					format(temp_command,sizeof(temp_command),"/me %s на место прошлого выхода из игры.",user[playerid][gender]?"вернулся":"вернулась");
					cmd::me(playerid,temp_command);
					DeletePVar(playerid,"LastPosX");
					DeletePVar(playerid,"LastPosY");
					DeletePVar(playerid,"LastPosZ");
					DeletePVar(playerid,"LastPosFA");
					DeletePVar(playerid,"LastPosInterior");
					DeletePVar(playerid,"LastPosVirtualWorld");
				}
			}
		}
		case dBuyLicenses:{
			if(response){
				if(user[playerid][licenses][listitem+1]){

				}
				else{
					if(user[playerid][money] >= infoAboutLicenses[listitem][0]){
						//if(user[playerid][level] >= infoAboutLicenses[listitem][1]){
							user[playerid][licenses][listitem+1]=1;
							givePlayerMoney(playerid,infoAboutLicenses[listitem][0]);
							new temp[(3-2+1)*MAX_LICENSES];
							for(new i=0; i<MAX_LICENSES; i++){
								strcat(temp,user[playerid][licenses][i]);
								if(i != MAX_LICENSES-1){
									strcat(temp,"|");
								}
							}
							new query[59-2-2-2+sizeof(temp)+11+11];
							mysql_format(mysql_connection,query,sizeof(query),"update`users`set`licenses`='%e',`money`='%i'where`id`='%i'",temp,user[playerid][money],user[playerid][id]);							
							mysql_query(mysql_connection,query,false);
						/*}
						else{
							SendClientMessage(playerid,-1,"LVL");//to do
						}*/
					}
					else{
						SendClientMessage(playerid,C_GREY,""RED"x"GREY" Для покупки данной лицензии у тебя не хватает денег.");
					}
				}
			}
		}
	}
	return true;
}

public OnPlayerSpawn(playerid){
	if(!GetPVarInt(playerid,"PlayerLogged")){
		Kick(playerid);
	}
	if(GetPVarInt(playerid,"LastPosSpawn")){
		ShowPlayerDialog(playerid,dLastPos,DIALOG_STYLE_MSGBOX,"Телепорт","\n\n\n\n"WHITE"Вернуться на место прошлого выхода из игры?\n\n\n","Да","Нет");
		DeletePVar(playerid,"LastPosSpawn");
	}
	switch(user[playerid][changerespawn]){
		case 1:{// вокзал сан фиерро
			SetPlayerPos(playerid,-1966.1068,121.8472,27.6875);
			SetPlayerFacingAngle(playerid,90.0);
			SetPlayerInterior(playerid,0);
			SetPlayerVirtualWorld(playerid,0);
		}
		case 2:{// отель лос сантос
			SetPlayerPos(playerid,2268.0000,1629.7000,1084.2438);
			SetPlayerFacingAngle(playerid,0.0);
			SetPlayerInterior(playerid,1);
			SetPlayerVirtualWorld(playerid,0);
		}
		default:{
			Kick(playerid);
		}
	}
	SetPlayerSkin(playerid,user[playerid][character]);
	GivePlayerMoney(playerid,user[playerid][money]);
	SetCameraBehindPlayer(playerid);
	return true;
}

public OnPlayerPickUpDynamicPickup(playerid, STREAMER_TAG_PICKUP:pickupid){
	if(pickupid == pickup_help){
		ShowPlayerDialog(playerid,dHelp,DIALOG_STYLE_LIST,"Помощь","Команды и чат.\nУровень.\nФракции.\nНедвижимость.\nРаботы.\nБолее подробная информация.","Читать","Выйти");
	}
	else if(pickupid == pickup_enter_driving_school){
		if(!user[playerid][licenses][LICENSE_DRIVING]){
			ShowPlayerDialog(playerid,NULL,DIALOG_STYLE_MSGBOX,"Информация Автошколы",""WHITE"* Для начала экзамена подойди к монитору и введи команду "GREEN"/taketest"WHITE" *\n\n\nДля ввода команд используй"GREEN" F6\n","ОК","");
		}
		SetPlayerPos(playerid,-2029.5052,-105.1260,1035.1719);
		SetPlayerFacingAngle(playerid,180.0);
		SetPlayerInterior(playerid,3);
	}
	else if(pickupid == pickup_exit_driving_school){
		SetPlayerPos(playerid,-2026.5930,-99.1141,35.1641);
		SetPlayerFacingAngle(playerid,0.0);
		SetPlayerInterior(playerid,0);
	}
	else if(pickupid == pickup_buy_licenses){
		ShowPlayerDialog(playerid,dBuyLicenses,DIALOG_STYLE_LIST,"Покупка лицензий","Лицензия на ношение оружия (2LvL+120000$)\nЛицензия на управление воздушным транспортом (3LvL+200000$)\nЛицензия на мото транспорт (1LvL+50000$)\nЛицензия на водный транспорт (2LvL+100000$)","Купить","Отмена");
		SetPlayerPos(playerid,-2024.2720,-118.8759,1035.1719);
		SetPlayerFacingAngle(playerid,270.0);
	}
	else if(pickupid == pickup_enter_to_hotel){
		SetPlayerPos(playerid,2268.4277,1649.6089,1084.2344);
		SetPlayerFacingAngle(playerid,13.4270);
		SetPlayerInterior(playerid,1);
	}
	else if(pickupid ==  pickup_exit_from_hotel){
		SetPlayerPos(playerid,1286.5206,-1274.7014,13.5397);
		SetPlayerFacingAngle(playerid,94.8944);
		SetPlayerInterior(playerid,0);
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

showReferalDialog(playerid){
	ShowPlayerDialog(playerid,dRegistrationReferal,DIALOG_STYLE_INPUT,"Регистрация",""WHITE"Если тебя кто-то пригласил на сервер, то введи его ник в поле ниже.\n"GREEN"• Когда ты достигнешь 5 уровня, пригласивший тебя игрок получит бонус.","Далее","Пропустить");
}

showAuthorizationDialog(playerid){
	new string[310-2+MAX_PLAYER_NAME-2+11];
	format(string,sizeof(string),"\n\n\n\n"WHITE"Привет "BLUE"%s"WHITE"\n\nМы рады снова видеть тебя на Orio["BLUE"N"WHITE"] RPG!\nНаш адрес в интернете - "BLUE""SITE_LINK""WHITE"\nТвой уникальный номер аккаунта: "BLUE"%i\n"WHITE"Дата регистрации: "BLUE"%s\n\n\n\n"WHITE"Для авторизации на сервере введите пароль к аккаунту:",user[playerid][name],user[playerid][id],user[playerid][dateofregister]);
	ShowPlayerDialog(playerid,dAuthorization,DIALOG_STYLE_PASSWORD,"Авторизация",string,"Войти","Отмена");
}

showRestoreUserDialog(playerid){
	ShowPlayerDialog(playerid,dAuthorizationRestore,DIALOG_STYLE_INPUT,"Восстановление аккаунта",""WHITE"Введи привязанный к аккаунту Email адрес, для восстановления пароля!\nЕсли ты не хочешь восстанавливать пароль, просто нажми \"Выход\"","Далее","Выход");
}

showRestoreUserCodeDialog(playerid){
	ShowPlayerDialog(playerid,dAuthorizationRestoreCode,DIALOG_STYLE_INPUT,"Подтверждение EMail",""WHITE"На твой EMail отправлен 8-ми значный код подтверждения!\nВведи его в поле ниже и нажми \"Далее\"\n"RED"• Если письмо не пришло, проверь папку \"Спам\"\n• У тебя одна попытка ввода кода подтверждения!","Далее","");
}

loadUser(playerid,Cache:cache_users){
	cache_set_active(cache_users,mysql_connection);
	if(cache_get_row_count(mysql_connection)){
		cache_get_field_content(0,"email",user[playerid][email],mysql_connection,32);
		cache_get_field_content(0,"referal",user[playerid][referal],mysql_connection,MAX_PLAYER_NAME);
		user[playerid][gender]=cache_get_field_content_int(0,"gender",mysql_connection);
		user[playerid][character]=cache_get_field_content_int(0,"character",mysql_connection);
		user[playerid][money]=cache_get_field_content_int(0,"money",mysql_connection);
		user[playerid][bankmoney]=cache_get_field_content_int(0,"bankmoney",mysql_connection);
		new temp_lastpos[50];
		cache_get_field_content(0,"lastpos",temp_lastpos,mysql_connection,sizeof(temp_lastpos));
		new Float:temp_x,Float:temp_y,Float:temp_z,Float:temp_fa,temp_interior,temp_virtualworld;
		sscanf(temp_lastpos,"p<|>ffffii",temp_x,temp_y,temp_z,temp_fa,temp_interior,temp_virtualworld);
		if(temp_x && temp_y && temp_z){
			SetPVarFloat(playerid,"LastPosX",temp_x);
			SetPVarFloat(playerid,"LastPosY",temp_y);
			SetPVarFloat(playerid,"LastPosZ",temp_z);
			SetPVarFloat(playerid,"LastPosFA",temp_fa);
			SetPVarInt(playerid,"LastPosInterior",temp_interior);
			SetPVarInt(playerid,"LastPosVirtualWorld",temp_virtualworld);
			SetPVarInt(playerid,"LastPosSpawn",1);
		}
		new temp_licenses[MAX_LICENSES*3];
		cache_get_field_content(0,"licenses",temp_licenses,mysql_connection,sizeof(temp_licenses));
		new temp_sscanf[13-2+1];		
		format(temp_sscanf,sizeof(temp_sscanf),"p<|>a<i>[%i]",MAX_LICENSES);
		sscanf(temp_licenses,temp_sscanf,user[playerid][licenses]);
	}
}

forward kick_player(playerid);
public kick_player(playerid){
	Kick(playerid);
}

forward OnPlayerCommandReceived(playerid, cmdtext[]);
public OnPlayerCommandReceived(playerid, cmdtext[]){
    if(!GetPVarInt(playerid,"PlayerLogged")){
        return false;
    }
    return true;
}

ProxDetector(Float:radi, playerid, const string[],col1,col2,col3,col4,col5){
	if(GetPVarInt(playerid,"PlayerLogged")){
		new Float:posx, Float:posy, Float:posz;
		new Float:oldposx, Float:oldposy, Float:oldposz;
		new Float:tempposx, Float:tempposy, Float:tempposz;
		GetPlayerPos(playerid, oldposx, oldposy, oldposz);
		for(new i=0; i<MAX_PLAYERS; i++){
			GetPlayerPos(i, posx, posy, posz);
			tempposx = (oldposx -posx);
			tempposy = (oldposy -posy);
			tempposz = (oldposz -posz);
			if (((tempposx < radi/16) && (tempposx > -radi/16)) && ((tempposy < radi/16) && (tempposy > -radi/16)) && ((tempposz < radi/16) && (tempposz > -radi/16))){
				SendClientMessage(i, col1, string);
			}
			else if (((tempposx < radi/8) && (tempposx > -radi/8)) && ((tempposy < radi/8) && (tempposy > -radi/8)) && ((tempposz < radi/8) && (tempposz > -radi/8))){
				SendClientMessage(i, col2, string);
			}
			else if (((tempposx < radi/4) && (tempposx > -radi/4)) && ((tempposy < radi/4) && (tempposy > -radi/4)) && ((tempposz < radi/4) && (tempposz > -radi/4))){
				SendClientMessage(i, col3, string);
			}
			else if (((tempposx < radi/2) && (tempposx > -radi/2)) && ((tempposy < radi/2) && (tempposy > -radi/2)) && ((tempposz < radi/2) && (tempposz > -radi/2))){
				SendClientMessage(i, col4, string);
			}
			else if (((tempposx < radi) && (tempposx > -radi)) && ((tempposy < radi) && (tempposy > -radi)) && ((tempposz < radi) && (tempposz > -radi))){
				SendClientMessage(i, col5, string);
			}
		}
	}
	return true;
}

givePlayerMoney(playerid,value){
	if(GetPVarInt(playerid,"PlayerLogged")){
		ResetPlayerMoney(playerid);
		user[playerid][money]+=value;
		GivePlayerMoney(playerid,user[playerid][money]);
	}
}

// Команды игроков

CMD:me(playerid,params[]){
	new temp_text[128];
	if(sscanf(params,"s[128]",temp_text)){
		SendClientMessage(playerid,C_GREY,"Используй: /me [действие]");
		return true;
	}
	new string[6-2-2+MAX_PLAYER_NAME+128];
	format(string,sizeof(string),"%s %s",user[playerid][name],temp_text);	
	ProxDetector(25.0,playerid,string,C_PURPLE,C_PURPLE,C_PURPLE,C_PURPLE,C_PURPLE);
	return true;
}

CMD:changerespawn(playerid){
	if(user[playerid][licenses][LICENSE_DRIVING]){
		if(IsPlayerInRangeOfPoint(playerid,5.0,-1976.5925,141.8520,27.6875) || IsPlayerInRangeOfPoint(playerid,5.0,1285.1329,-1272.0217,13.5381)){//SF
			user[playerid][changerespawn]=(user[playerid][changerespawn]==1)?2:1;
			SendClientMessage(playerid,-1,(user[playerid][changerespawn]==1)?"Теперь вы будешь возрождаться на вокзале "GREEN"San Fierro"WHITE".":"Теперь ты будешь возрождаться в отеле "GREEN"Los Santos"WHITE".");
		}
		new query[51-2-2+1+11];
		mysql_format(mysql_connection,query,sizeof(query),"update`users`set`changerespawn`='%i'where`id`='%i'",user[playerid][changerespawn],user[playerid][id]);		
		mysql_query(mysql_connection,query,false);
	}
	else{
		SendClientMessage(playerid,-1,"");
		SendClientMessage(playerid,-1,"");
		SendClientMessage(playerid,C_GREY,""RED"x"GREY" Ты не можешь сменить место спавна! Тебе необходимо сначала получить водительские права.");
		SendClientMessage(playerid,-1,"Набери "GREEN"/kpk"WHITE", выбери пункты [ GPS навигатор - Важные места - Автошкола ].");
		SendClientMessage(playerid,-1,"");
	}
	return true;
}