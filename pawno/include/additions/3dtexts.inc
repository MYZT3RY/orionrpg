#include <additions/configuration>
#include <additions/colors>

Create3DTexts(){
	CreateDynamic3DTextLabel("Наш адрес в интернете "SUNBURN""SITE_LINK"\n"WHITE"Страничка [В]Контакте - "SUNBURN""VK_LINK""WHITE"\nНаш сервер:\nOrioN Server №1 IP:"IP_SERVER"",-1,-1994.7456,137.8349,30.4119,100.0,INVALID_PLAYER_ID,INVALID_VEHICLE_ID,1);
	CreateDynamic3DTextLabel("* * * "LIGHT_STEEL_BLUE"П О М О Щ Ь"WHITE" * * *",-1,-1977.4960,133.5098,27.6940,50.0,INVALID_PLAYER_ID,INVALID_VEHICLE_ID,1);
	CreateDynamic3DTextLabel("Тут можно изменить место возрождения\n"WHITE"Используй: /changerespawn",C_SUNBURN,-1976.5925,141.8520,27.6875,50.0,INVALID_PLAYER_ID,INVALID_VEHICLE_ID,1);
	CreateDynamic3DTextLabel("Введи "SUNBURN"/taketest"WHITE" для начала урока",-1,-2026.7585,-114.3428,1035.1719,50.0,INVALID_PLAYER_ID,INVALID_VEHICLE_ID,1,-1,3);
	CreateDynamic3DTextLabel("|------ Продажа лицензий ------|",-1,-2022.2257,-116.7993,1035.1719,50.0,INVALID_PLAYER_ID,INVALID_VEHICLE_ID,1,-1,3);
}