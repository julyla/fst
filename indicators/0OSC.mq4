// Вот теперь может и сбудется...
#property copyright "Hohla"
#property link      "hohla@mail.ru"

#property indicator_separate_window
#property indicator_buffers 4
#property indicator_color1 SpringGreen
#property indicator_color2 Green
#property indicator_color3 Gray
#property indicator_color4 Gray

extern int OSC=5;
extern int HL=1;  // Способ расчета HL
extern int iHL=9; // Коэф. расчета HL
extern int PerCnt=0;   // способ расчета периода HL (используется тока при HL=1);

double H,L,H1,L1,H2,L2,H3,L3,Buffer0[],Buffer1[],Buffer2[],Buffer3[],porog,lo,hi,lo1,hi1,temp, hl[1000];
int i,j;

int OnInit(void){//ЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖ
   string short_name;
   IndicatorBuffers(4);
   SetIndexStyle(0,DRAW_LINE); 
   SetIndexBuffer(0,Buffer0);
   SetIndexStyle(1,DRAW_LINE); 
   SetIndexBuffer(1,Buffer1);
   SetIndexStyle(2,DRAW_LINE); 
   SetIndexBuffer(2,Buffer2);
   SetIndexStyle(3,DRAW_LINE); 
   SetIndexBuffer(3,Buffer3);
   switch (OSC){
         case 1:  short_name="1: HL/sHL (HL="+HL+", iHL="+iHL+", PerCnt="+PerCnt+") ";break; // Отношение последней HL к средней HL, посчитанной за per раз
         case 2:  short_name="2: Canal  (HL="+HL+", iHL="+iHL+", PerCnt="+PerCnt+") ";break; // Цена HLC/3 в канале 
         case 3:  short_name="3: LastHL (HL="+HL+", iHL="+iHL+", PerCnt="+PerCnt+") ";break; // фиксируются экстремумы HL до формирования следующих
         case 4:  short_name="4: LastHL (HL="+HL+", iHL="+iHL+", PerCnt="+PerCnt+") ";break; // фиксируются вершины экстремумов HL до формирования следующих
         case 5:  short_name="5: Fractal (HL="+HL+", iHL="+iHL+", PerCnt="+PerCnt+") ";break; // фракталы по HiLo
         }
   IndicatorShortName(short_name);
   SetIndexLabel(0,short_name);
   return (INIT_SUCCEEDED); // "0"-Успешная инициализация.
   }//ЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖ

int start(){//ЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖ
   // при использовании в расчете индикатора внешнего индикатора необходимо учитывать "поведение" нулевого бара. Если при расчете не фиксируются любые изменения внешнего индикатора,          
   // например как запись значения в массив (п.1), то можно использовать нулевой бар, т.к. в процессе формирования его значение не запоминается, и в конце концов примет конечное значение.
   // если же нулевой бар фиксируется, то может зафиксироватся неправильное его значение, что приведет потом хз к чему...  
   int N,CountBars=Bars-IndicatorCounted()-1;
   for (i=CountBars; i>0; i--){
      H =iCustom(NULL,0,"0HL",HL,iHL,PerCnt,0,i);   
      L =iCustom(NULL,0,"0HL",HL,iHL,PerCnt,1,i);
      H1=iCustom(NULL,0,"0HL",HL,iHL,PerCnt,0,i+1);   // щщитаем прошлые hi / lo
      L1=iCustom(NULL,0,"0HL",HL,iHL,PerCnt,1,i+1);
      H2=iCustom(NULL,0,"0HL",HL,iHL,PerCnt,0,i+2);   // щщитаем позапрошлые hi / lo
      L2=iCustom(NULL,0,"0HL",HL,iHL,PerCnt,1,i+2);
      H3=iCustom(NULL,0,"0HL",HL,iHL,PerCnt,0,i+3);   // щщитаем позапрошлые hi / lo
      L3=iCustom(NULL,0,"0HL",HL,iHL,PerCnt,1,i+3);
      switch (OSC){
         case 1: // Отношение последней HL к средней HL, посчитанной за per раз  ////////////////////////////////////////////////////////////////////////////////////////////////////
            N=30; // количество диапазонов HL для усреднения
            // !!!! если использовать для расчета текущий (нулевой) бар H(i), то система выдает ложные сигналы, т.к. при формировании бара может многократно меняться hl[0], а hl[0] сразу сохраняется и дальнейшая коррекция при наступлении нового бара, как в других индикаторах, не использующих массив индикатора уже невозможна 
            if (hl[0]!=H-L){// сформировался новый диапазон HL
               temp=0;
               hl[0]=H-L;   // обновим последний диапазон
               for (j=N; j>0; j--){
                  hl[j]=hl[j-1]; // пересортируем массив, да так, чтоб новое значение было с индексом 1 
                  temp+=hl[j];   // за одно посчитаем сумму всех значений
                  }
               temp/=N; // посчитаем среднее N диапазонов без учета последнего диапазона
               }
            Buffer0[i]=temp;  // Среднее значение N диапазонов HL
            Buffer1[i]=hl[0]; // Последний диапазон HL
         break;
         case 2: // Цена HLC/3 в канале //////////////////////////////////////////////////////////////////////////////////////////////////////////
            double M=(iHigh(NULL,0,i)+iLow(NULL,0,i)+iClose(NULL,0,i))/3;
            if (H-L>0) temp=(M-L)/(H-L)-0.5; // нормализация к нулевому значению
            if (H>H1) porog=0.5; // Новый максимум
            if (L<L1) porog=-0.5; // Новый минимум
            Buffer0[i]=temp;
            Buffer1[i]=porog; 
         break;
         case 3: // фиксируются экстремумы HL до формирования следующих
            if (L1>L)  lo=L; // сформировался очередной минимум 
            if (H1<H)  hi=H; // сформировался очередной максимум
            Buffer0[i]=lo;
            Buffer1[i]=hi; 
            Buffer2[i]=H;
            Buffer3[i]=L;  
         break;
         case 4: // фиксируются вершины экстремумов HL до формирования следующих
            if (L3>L2 && L2<=L1)  lo=L2; // сформировался очередной минимум 
            if (H3<H2 && H2>=H1)  hi=H2; // сформировался очередной максимум
            Buffer0[i]=lo;
            Buffer1[i]=hi; 
            Buffer2[i]=H1;
            Buffer3[i]=L1;  
         break;
         case 5: // фракталы по Hi Lo
            if (L3>L2 && L2<=L1)  temp=1; // сформировался очередной минимум, тренд вверх 
            if (H3<H2 && H2>=H1)  temp=-1; // сформировался очередной максимум, тренд вниз
            Buffer0[i]=temp;
            Buffer1[i]=0; 
            Buffer2[i]=0;
            Buffer3[i]=0;  
         break;
      }  }
   return(0);
   }//ЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖЖ
  
   

