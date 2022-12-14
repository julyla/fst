double MoneyManagement(double Stop){// ММ ЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖ
   if (Risk==0) {Lot=0;   return(Lot);} 
   double   MinLot =MarketInfo(SYMBOL,MODE_MINLOT), // CurDD - глобальная, т.к. передается в ф. TradeHistoryWrite() 
            MaxLot =MarketInfo(SYMBOL,MODE_MAXLOT);        
   if (Risk>MaxRisk) Risk=MaxRisk*0.95;// проверка на ошибочное значение риска
   CurDD=CurrentDD(); // последняя незакрытая просадка эксперта (не максимальной) 
   if (Stop<=0)                              {REPORT("MM: Stop<=0!");    return (-MinLot);}
   if (MarketInfo(SYMBOL,MODE_POINT)<=0)     {REPORT("MM: POINT<=0!");   return (-MinLot);}
   if (MarketInfo(SYMBOL,MODE_TICKVALUE)<=0) {REPORT("MM: TICKVAL<0!");  return (-MinLot);}
   if (CurDD>HistDD)                         {REPORT("MM: CurDD>HistDD!: "+DoubleToStr(CurDD,0)+">"+DoubleToStr(HistDD,0));return (-MinLot);}
   // см.Расчет залога http://www.alpari.ru/ru/help/forex/?tab=1&slider=margins#margin1
   // Margin = Contract*Lot/Leverage = 100000*Lot/100  
   // MaxLotForMargin=NormalizeDouble(AccountFreeMargin()/MarketInfo(SYMBOL,MODE_MARGINREQUIRED),LotDigits) // Макс. кол-во лотов для текущей маржи
   Lot = NormalizeDouble(Depo(MM)*Risk*0.01 / (Stop/MarketInfo(SYMBOL,MODE_POINT)*MarketInfo(SYMBOL,MODE_TICKVALUE)), LotDigits); // размер стопа через Стоимость пункта. См. калькулятор трейдера http://www.alpari.ru/ru/calculator/
   if (Lot<MinLot) Lot=MinLot;   // Проверка на соответствие условиям ДЦ
   if (Lot>MaxLot) Lot=MaxLot; //Print("Risk=",Risk," RiskChecker=",RiskChecker(Lot,Stop));
   if (RiskChecker(Lot,Stop,SYMBOL)>MaxRisk) {REPORT("MM: RiskChecker="+DoubleToStr(RiskChecker(Lot,Stop,SYMBOL),2)+"% - Trade Disable!"); return (-MinLot);}// Не позволяем превышать риск MaxRisk%! 
   return (Lot);
   }//ЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖ

double RiskChecker(double lot, double Stop, string SYM){// Проверим, какому риску будет соответствовать расчитанный Лот:  //ЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖ
   if (MarketInfo(SYM,MODE_TICKVALUE)<=0) {REPORT("RiskChecker(): "+SYM+" TickValue<0"); return (100);}
   if (MarketInfo(SYM,MODE_POINT)<=0)     {REPORT("RiskChecker(): POINT<=0!"); return (-1);}
   return (NormalizeDouble(lot * (Stop/MarketInfo(SYM,MODE_POINT)*MarketInfo(SYM,MODE_TICKVALUE)) / AccountBalance()*100,2));
   }//ЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖ
   
int CurrentDD(){// расчет последней незакрытой просадки эксперта (не максимальной)  ЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖ
   double MaxExpertProfit=LastTestDD, ExpertProfit=0, profit=0;
   int Ord;
   for(Ord=0; Ord<OrdersHistoryTotal(); Ord++){// находим среди всей истории сделок эксперта ПОСЛЕДНЮЮ просадку и измеряем ее от макушки баланса до текущего значения (Не до минимального!)
      if (OrderSelect(Ord,SELECT_BY_POS,MODE_HISTORY)==true && OrderMagicNumber()==Magic && OrderCloseTime()>TestEndTime){
         profit=OrderProfit()+OrderSwap()+OrderCommission(); // прибыль от выбранного ордера в пунктах
         if (profit!=0){ 
            profit=profit/OrderLots()/MarketInfo(SYMBOL,MODE_TICKVALUE)*0.1;
            ExpertProfit+=profit; // текущая прибыль эксперта
            if (ExpertProfit>MaxExpertProfit) MaxExpertProfit=ExpertProfit; // Print(" CurDD(): magic=",Magic," profit=",profit," MaxExpertProfit=",MaxExpertProfit," ExpertProfit=",ExpertProfit," OrderCloseTime()=",TimeToStr(OrderCloseTime(),TIME_SECONDS));// максимальная прибыль эксперта                  
      }  }  } 
   return int(MaxExpertProfit-ExpertProfit); // значение последней незакрытой просадки эксперта (не максимальной)
   }//ЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖ
 
double Depo(int TypeMM){ // Расчет части депозита, от которой берется процент для совершения сделки  ЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖ
   double Deposite, ExpMaxBalance=AccountBalance(); // индивидуальная переменная, должна храниться в файле с временными параметрами
   switch (TypeMM){
      case 1: // Классический Антимартингейл
         Deposite=AccountBalance();   //Print("ExpMaxDD=",ExpMaxDD," CarrentDD=",cDD," Balance=",AccountBalance()," Deposite=",Deposite, " K=",100*(ExpMaxDD-cDD)/ExpMaxDD,"%");// Дополнительно уменьшаем риск эксперта пропорционально глубине его текущей просадки      
      break; 
      case 2: // Индивидуальный баланс. Фиксируется начало индивидуальной просадки и риск начинает увеличиваться до выхода из нее за счет прироста баланса от прибыльных систем. 
         // Но не превышает установленного риска для данной системы, если баланс продолжает снижаться.  
         
         if (CurrentDD()==0 && AccountBalance()>ExpMaxBalance) ExpMaxBalance=AccountBalance(); // Лот увеличивается только если система в плюсе и общий баланс растет. Т.е. если другие системы не сливают. 
         Deposite=MathMin(ExpMaxBalance,AccountBalance()); // Не превышаем установленного риска
      break; 
      case 3: // Процент от общего максимально достигнутого баланса.
         // При просадке экспертов лот не понижается (риск растет вплоть до 10%). 
         // Выход из просадки осуществляется с большей скоростью за счет растущего баланса от друхих систем. 
         // При этом оказывается значителььное влияние убыточных систем на общий баланс. 
         Deposite=GlobalVariableGet("MaxBalance");
         if (AccountBalance()>Deposite) Deposite=AccountBalance();
         GlobalVariableSet("MaxBalance",Deposite);
      break;
      case 4: // Общий баланс с дополнительным сокращением риска при индивидуальной просадке
         Deposite=AccountBalance()-CurrentDD();  // Дополнительно уменьшаем риск эксперта пропорционально глубине его текущей просадки      
      break; 
      case 5: // Общий баланс с дополнительным сокращением риска при индивидуальной просадке
         Deposite=AccountBalance()*(HistDD-CurDD)/HistDD;   //Print("ExpMaxDD=",ExpMaxDD," CarrentDD=",cDD," Balance=",AccountBalance()," Deposite=",Deposite, " K=",100*(ExpMaxDD-cDD)/ExpMaxDD,"%");// Дополнительно уменьшаем риск эксперта пропорционально глубине его текущей просадки      
      break; 
      default: Deposite=AccountBalance(); //Deposite=AccountBalance(); // Классический Антимартингейл
      }
   return (Deposite);
   }//ЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖ

