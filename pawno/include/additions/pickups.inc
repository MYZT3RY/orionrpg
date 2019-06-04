new pickup_help;

new pickup_enter_driving_school,
	pickup_exit_driving_school;

new pickup_buy_licenses;

new pickup_enter_to_hotel,
	pickup_exit_from_hotel;

CreatePickups(){
	CreateDynamicPickup(1314,23,-1976.5925,141.8520,27.6875);//changerespawn SF
	pickup_help=CreateDynamicPickup(1239,2,-1977.4960,133.5098,27.6940);//помощь
	pickup_enter_driving_school=CreateDynamicPickup(1318,23,-2026.5402,-100.6677,35.1641);//вход в автошколу
	pickup_exit_driving_school=CreateDynamicPickup(1318,23,-2027.0006,-104.1541,1035.1719);//выход из автошколы
	pickup_buy_licenses=CreateDynamicPickup(1239,23,-2022.2257,-116.7993,1035.1719);//продажа лицензий
	CreateDynamicPickup(1239,23,-2026.7585,-114.3428,1035.1719);//taketest
	CreateDynamicPickup(1314,23,1285.1329,-1272.0217,13.5381);//changerespawn LS
	pickup_enter_to_hotel=CreateDynamicPickup(1318,23,1289.1704,-1272.7886,13.5422);//вход в отель лс
	pickup_exit_from_hotel=CreateDynamicPickup(1318,23,2266.3594,1647.3431,1084.2344,-1,1);//выход из отеля лс
}