int OnInit(){// функции сохранения и восстановления параметров на случай отключения терминала в течении часа // ЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖ
   if (!IsTesting() && !IsOptimization()) {Real=true;} // на реале формирование файла проверки обязательно  
   InitDeposit=AccountBalance();DayMinEquity=InitDeposit;
   SYMBOL=Symbol();ERROR_CHECK("OnInit() 1");
   string AccComp="test"; 
   if (AccountCompany()!="") AccComp=AccountCompany();
   Company=StringSubstr(AccComp,0,StringFind(AccComp," ",0)); // Первое слово до пробела
   StartDate=TimeToStr(TimeCurrent(),TIME_DATE); // дата начала оптимизации/тестированиЯ
   if (MarketInfo(Symbol(),MODE_LOTSTEP)<0.1) LotDigits=2; else LotDigits=1;
   CHART_SETTINGS();
   if (Real){
      if (Bars<1000) MessageBox("Before(): History too short < 1000 bars!"); // история слишком короткая, индикаторы могут посчитаться неверно
      BackTest=0; // для реала - флаг начала торгового цикла
      int ms=0;
      for (int i=0; i<StringLen(Symbol()); i++)  ms+=StringGetChar(Symbol(),i)/10; 
      ms*=Period(); while(ms<1000) ms*=10; // индивидуальная пауза для каждого эксперта, чтобы не стартовали разом
      Sleep(ms); Print("Start: Magic=",Magic);
      if (Risk==0) Aggress=1; // Если в настройках выставить риск>0, то риск, считанный из #.csv будет увеличен в данное количество раз. 
      else {Aggress=Risk; MaxRisk*=Risk; Alert(" WARNING, Risk x ",Aggress,"  MaxRisk=",MaxRisk, " !!!");} 
      INPUT_FILE_READ(); // занесение в массив считанных из csv файла входных параметров всех экспертов
      GlobalVariableSet("RepFile",0); // флаг доступа к файлу с репортами
      GlobalVariableSet("CanTrade",0); // заводим глобал для огранизации доступа к терминалу
      GlobalVariableSet("CHECK_OUT_Time",TimeCurrent()); // глобал для обеспечения периодичности проверки ордеров
      Print("Init() ",ExpertName,"-",VERSION," ",Symbol()+S0(Period()), " Last Start BarTime=",TimeToStr(BarTime,TIME_DATE | TIME_MINUTES),", ExpetrsTotal =",ExpTotal,", StartPause =",ms,"ms");
      if (UninitializeReason()==1) REPORT("Last Exit=Program Remove");
      FileDelete("Reports.csv"); 
      }
   else{
      if (BackTest>0){// Загрузка параметров эксперта из файла отчета *.csv.
         INPUT_FILE_READ(); // занесение в массив считанных из csv файла входных параметров из строки BackTest
         if (ExpTotal<0) {BackTest=ExpTotal; Print(" Period or Symbol or Expert  NOT corresponds");}
         double RiskTmp=Risk;
         DATA_PROCESSING(0, READ_ARR); // считываем параметры строки "BackTest-2" в переменные эксперта
         Risk=RiskTmp; 
         }
      else{
         MAGIC_GENERATOR();
         INPUT_PARAMETERS_PRINT();  // ПЕЧАТЬ В ЛЕВОЙ ЧАСТИ ГРАФИКА ВХОДНЫХ ПАРАМЕТРОВ ЭКСПЕРТА  
         } 
      TimeCounter();
      }
   return (INIT_SUCCEEDED);   
   }  
// ЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖ
// ЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖ
bool Count(){// Общие расчеты для всего эксперта 
   RefreshRates();
   history="";
   SYMBOL=Symbol();
   Per=Period();
   MARKET_UPDATE();
   Mid1=NormalizeDouble((High[1]+Low[1]+Close[1])/3,Digits);
   Mid2=NormalizeDouble((High[2]+Low[2]+Close[2])/3,Digits);
   atr=PerAdapter*iCustom(NULL,0,"ATR2",a*a,A*A,0,1); //Print("atr=",atr);
   ATR=PerAdapter*iCustom(NULL,0,"ATR2",a*a,A*A,1,1); //Print("ATR=",ATR);
   // Print(TimeToStr(Time[1],TIME_DATE | TIME_MINUTES)," Bars=",Bars," ATR=",ATR);
   if (ATR==0){
      REPORT("!!! ATR=0, A="+S0(A)+" Bars="+S0(Bars));
      Print("Count(): ATR=",ATR); 
      return(false);}
   // Расчет минимальной прибыли, без которой не хочется закрываться
   if (Op<0)  Present=-20*ATR; // при отрицательных значениях oP поХ c каким кушем выходить
   else       Present=(Op+1)*(Op+1)*0.1*ATR; // пороговая прибыль, без которой не закрываемся  0.1  0.4  0.9  1.6  2.5  3.6 
   // Расчет экстремумов HL   
   H=iCustom(NULL,0,"$HL",HL,HLk,0,1);  //
   L=iCustom(NULL,0,"$HL",HL,HLk,1,1);  //
   //REPORT(" Count for "+Magic+"__");
// НАЙДЕМ МАКСИМАЛЬНЫЕ/МИНИМАЛЬНЫЕ ЦЕНЫ С МОМЕНТА ОТКРЫТИЯ ПОЗ ////////////////////////////////////////////////////////////////////////
   if (BUY>0){
      int i=1; MinFromBuy=Low[1]; MaxFromBuy=High[1]; //Print("BuyOrderOpenTime()=",OrderOpenTime());
      while (Time[i]>=BuyTime){
         if (High[i]>MaxFromBuy) MaxFromBuy=High[i];
         if (Low[i]<MinFromBuy)  MinFromBuy=Low[i];
         i++;  
      }  } // Print(" BuyTime=",BuyTime," Time=",Time[i],",  MaxFromBuy=",MaxFromBuy," MinFromBuy=",MinFromBuy, " Low[1]=",Low[1]);
   if (SELL>0){
      int i=1; MinFromSell=Low[1]; MaxFromSell=High[1]; //Print("SellOrderOpenTime()=",OrderOpenTime());
      while (Time[i]>=SellTime){
         if (High[i]>MaxFromSell) MaxFromSell=High[i];
         if (Low[i]<MinFromSell)  MinFromSell=Low[i];
         i++;  //Print(" SellTime=",Time[i]," High[i]=",High[i]," Low[i]=",Low[i]); 
     }  }
   if (tk==0 && ExpirHours>0)  Expiration=Time[0]+datetime(ExpirHours*Period()*60-180); // уменьшаем период на три минутки, чтоб совпадало с реалом    
   else Expiration=0; 
   Buy.New=0; Sel.New=0; Buy.Stp=0; Buy.Prf=0; Sel.Stp=0; Sel.Prf=0; //
   ERROR_CHECK("COUNT");
   return (true);
   }////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void TimeCounter(){// Находим время входа и выхода  //////////////////////////////////////////////////////////////////     
   PerAdapter=MathPow(60.00/Period(),0.5); //Print("PerAdapter=",PerAdapter);
   if (tk==0){ // без временного фильтра, активны только GTC и Tper(удержание отрытой позы)
      Tin=0;
      switch(T0){// расчет времени жизни отложников
         case 1: ExpirHours= 1;  break; 
         case 2: ExpirHours= 2;  break; 
         case 3: ExpirHours= 3;  break;     
         case 4: ExpirHours= 5;  break;
         case 5: ExpirHours= 8;  break;
         case 6: ExpirHours=13;  break;
         case 7: ExpirHours=21;  break;
         default:ExpirHours=0;   break; // при Т0=0, 8
         }
      switch(T1){// Время удержания открытой позы и период сделки 
         case 1: Tper= 1;  break;  
         case 2: Tper= 2;  break;  
         case 3: Tper= 3;  break;  
         case 4: Tper= 5;  break;     
         case 5: Tper= 8;  break;  
         case 6: Tper=13;  break;  
         case 7: Tper=21;  break;  
         default:Tper=0; // бесконечно 
         }
      ExpirHours=int(ExpirHours*PerAdapter);
      Tper*=PerAdapter;
      }
   else{ // при tk>0 торговля ведется в определенный период
      ExpirHours=0; Tper=0;   
      Tin=(8*(tk-1) + T0-1); // с какого бара начинать торговлю
      switch(T1){// Время удержания открытой позы и период сделки 
         case 1: Tout=Tin+ 1; break; 
         case 2: Tout=Tin+ 2; break; 
         case 3: Tout=Tin+ 3; break; 
         case 4: Tout=Tin+ 5; break;      
         case 5: Tout=Tin+ 8; break;
         case 6: Tout=Tin+12; break;
         case 7: Tout=Tin+16; break;
         default:Tout=Tin+20; break;// при Т1=0, 8
         }
      Tin*=PerAdapter;   
      Tout*=PerAdapter; 
      temp=60/Period()*24; // кол-во баров в сутках   
      if (Tout>=temp) Tout-=temp;   // если время начала торговли будет 18:00, а Период 20 часов, то разрешено торговать с 18:00 до 14:00      
      //Print("OLD Tin=",Tin," Tout=",Tout," PerAdapter=",PerAdapter,".  Или с ",MathFloor((Tin*Period())/60),":",Tin*Period()-MathFloor((Tin*Period())/60)*60," по ",MathFloor((Tout*Period())/60),":",Tout*Period()-MathFloor((Tout*Period())/60)*60);
   }  }////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
bool FineTime(){ // время, в которое разрешено торговать //////////////////////////////////////////////////////////////////////////////////////////////////
   if (tk==0) return (true); // при tk=0 ограничение по времени не работает
   else{
      temp=(TimeHour(Time[0])*60+Minute())/Period(); // приводим текущее время в количесво баров с начала дня
      if ((Tin<Tout &&  Tin<=temp && temp<Tout) ||              //  00:00-нельзя / Tin-МОЖНО-Tout / нельзя-23:59
          (Tout<Tin && (Tin<=temp || (0<=temp && temp<Tout))))  //  00:00-можно / Tout-НЕЛЬЗЯ-Tin / можно-23:59  
         return (true); else return (false);   
   }  }////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////   
// ЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖ
// ЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖ
void TESTER_FILE_CREATE(string Inf, string TesterFileName){ // создание файла отчета со всеми характеристиками  //////////////////////////////////////////////////////////////////////////////////////////////////
   ResetLastError(); TesterFile=FileOpen(TesterFileName, FILE_READ|FILE_WRITE | FILE_SHARE_READ | FILE_SHARE_WRITE, ';'); 
   if (TesterFile<0) {REPORT("ERROR! TesterFileCreate()  Не могу создать файл "+TesterFileName); return;}
   string SymPer=Symbol()+DoubleToStr(Period(),0);
   //MAGIC_GENERATOR();
   if (FileReadString(TesterFile)==""){
      FileWrite(TesterFile,"INFO","SymPer",Str1,Str2,Str3,Str4,Str5,Str6,Str7,Str8,Str9,Str10,Str11,Str12,Str13,"Magic"); 
      DATA_PROCESSING(TesterFile, WRITE_HEAD);
      }
   FileSeek (TesterFile, 0,SEEK_END); // перемещаемся в конец   
   FileWrite(TesterFile,    Inf  , SymPer ,Prm1,Prm2,Prm3,Prm4,Prm5,Prm6,Prm7,Prm8,Prm9,Prm10,Prm11,Prm12,Prm13, Magic); 
   DATA_PROCESSING(TesterFile, WRITE_PARAM);
   FileSeek (TesterFile,-2,SEEK_END); FileWrite(TesterFile,"",0,0,0);
   }
// ЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖ
// ЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖ
void MAGIC_GENERATOR(){
   MagicLong=0;
   DATA_PROCESSING(0, MAGIC_GEN);   // генерит огромное чило MagicLong типа ulong складыая побитно все входные параметры
   ExpID=CODE(MagicLong);  // Уникальное 70-ти разрядное строковое имя из символов, сгенерированных на основе числа MagicLong 
   Magic=int(MagicLong);   // обрезаем до размеров, используемых в функциях OrderSend(), OrderModify()...
   if (Magic<0) Magic*=-1; // Отрицательный не нужен
   //Print (" MagicLong=",MagicLong," Magic=",Magic," ExpId=",ExpID);
   }  
// ЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖ
// ЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖ     
void INPUT_PARAMETERS_PRINT(){ // ПЕЧАТЬ В ЛЕВОЙ ЧАСТИ ГРАФИКА ВХОДНЫХ ПАРАМЕТРОВ ЭКСПЕРТА и создание файла настроек magic.set 
   if (IsOptimization()) return;
   string FileName=ExpertName+"_"+S0(Magic)+".set";   // TerminalInfoString(TERMINAL_DATA_PATH)+"\\tester\\files\\"+ExpertName+DoubleToString(Magic,0)+".txt";
   int file=FileOpen(FileName,FILE_WRITE|FILE_TXT);
   if (file<0){   Print("INPUT_PARAMETERS_PRINT: Can't write setter file ", FileName);  return;}
   LABEL("                  "+ExpertName+" Back="+S0(BackTest)+" Risk="+S1(Risk)+" MaxRisk="+S0(MaxRisk));
   LABEL("                  Magic="+S0(Magic)); LABEL(" "); 
   DATA_PROCESSING(file, LABEL_WRITE);
   FileClose(file); 
   ERROR_CHECK("INPUT_PARAMETERS_PRINT"); 
   }  


// ЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖ
// ЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖ    
void DATA_PROCESSING(int source, char ProcessingType){// универсальная ф-ция для записи/чтения парамеров, их печати на графике и генерации MagicLong   
   if (ProcessingType==LABEL_WRITE)   LABEL(" - T R E N D - ");///////////
   DATA("HL",  HL,   source,ProcessingType);
   DATA("HLk", HLk,  source,ProcessingType);
   DATA("TR",  TR,   source,ProcessingType);
   DATA("TRk", TRk,  source,ProcessingType);
   DATA("PerCnt",PerCnt,        source,ProcessingType);
   if (ProcessingType==LABEL_WRITE)   LABEL(" - I N P U T  - ");///////////
   DATA("Itr", Itr,  source,ProcessingType);
   DATA("IN",  IN,   source,ProcessingType);
   DATA("Ik",  Ik,   source,ProcessingType);
   DATA("Irev",Irev, source,ProcessingType);
   if (ProcessingType==LABEL_WRITE)   LABEL(" -  S T O P S  - ");//////////////// 
   DATA("Del", Del,  source,ProcessingType);
   DATA("Rev", Rev,  source,ProcessingType);
   DATA("D",   D,    source,ProcessingType);
   DATA("Iprice",Iprice,source,ProcessingType);
   DATA("S",   S,    source,ProcessingType);
   DATA("P",   P,    source,ProcessingType);
   DATA("PM",  PM,   source,ProcessingType);
   DATA("Pm",  Pm,   source,ProcessingType);
   if (ProcessingType==LABEL_WRITE)   LABEL(" -  T R A I L I N G  -");////////////////
   DATA("T",   T,    source,ProcessingType);
   DATA("TS",  TS,   source,ProcessingType);
   DATA("Tk",  Tk,   source,ProcessingType);
   DATA("TM",  TM,   source,ProcessingType);
   DATA("Tm",  Tm,   source,ProcessingType);
   if (ProcessingType==LABEL_WRITE)   LABEL(" -  O U T P U T  -");////////////////
   DATA("Op",  Op,   source,ProcessingType);
   DATA("OUT", OUT,  source,ProcessingType);
   DATA("Ok",  Ok,   source,ProcessingType);
   DATA("Orev",Orev, source,ProcessingType);
   DATA("Oprice",Oprice,        source,ProcessingType);
   if (ProcessingType==LABEL_WRITE)   LABEL(" -  A T R  -");////////////////
   DATA("A",   A,    source,ProcessingType);
   DATA("a",   a,    source,ProcessingType);
   if (ProcessingType==LABEL_WRITE)   LABEL(" -  T I M E  -");////////////////
   DATA("tk",  tk,source,ProcessingType);
   DATA("T0",  T0,   source,ProcessingType);
   DATA("T1",  T1,   source,ProcessingType);
   DATA("tp",  tp,   source,ProcessingType);
   if (ProcessingType==READ_ARR){
      TestEndTime=CSV[source].TestEndTime;
      OptPeriod=  CSV[source].OptPeriod;
      HistDD=     CSV[source].HistDD;
      LastTestDD= CSV[source].LastTestDD;
      Risk=       CSV[source].Risk;
      Magic=      CSV[source].Magic;
      RevBUY=     CSV[source].RevBUY; 
      RevSELL=    CSV[source].RevSELL; 
      ExpMemory=  CSV[source].ExpMemory;
      }
   ERROR_CHECK("DATA_PROCESSING");    
   }    
    
// ЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖ
// ЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖ     
void DATA(string name, char& param, int& source, char ProcessingType){// выбор типа обработки входных данных в DATA_PROCESSING
   char i=2; 
   switch (ProcessingType){// тип обработки входных данных
   case LABEL_WRITE: LABEL(name+"="+S0(param));  FileWrite(source,name+"=",S0(param));  break;
   case READ_FILE:   param=char(StrToDouble(FileReadString(source)));            break; 
   case READ_ARR:    param=CSV[BackTest-2].PRM[source];    source++;             break;//  в нулевую ячейку массива записывается вторая строка  
   case WRITE_HEAD:  FileSeek (source,-2,SEEK_END); FileWrite(source,"",name);   break;   
   case WRITE_PARAM: FileSeek (source,-2,SEEK_END); FileWrite(source,"",param);  break;    
   case MAGIC_GEN:   // формирование длинного числа из всех параметров эксперта
      while (i<param) {i*=2; if (i>4) break;} // кол-во зарзрядов (бит), необходимое для добавления нового параметра, но не более 3, чтобы не сильно растягивать число
      MagicLong*=i; // сдвиг MagicLong на i кол-во зарзрядов  
      MagicLong+=param; // Добавление очередного параметра
      break;
      }
   ERROR_CHECK("DATA");    
   }     
   
         