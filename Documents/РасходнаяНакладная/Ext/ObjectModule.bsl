﻿
Процедура ОбработкаПроведения(Отказ, Режим)
	Движения.ОстаткиНоменклатуры.Записывать = Истина;
	Движения.ОстаткиНоменклатуры.Записать();	 
	
	Блокировка = Новый БлокировкаДанных;
	ЭлементБлокировки = Блокировка.Добавить("РегистрНакопления.ОстаткиНоменклатуры");
	ЭлементБлокировки.УстановитьЗначение("Склад", Склад);
	ЭлементБлокировки.Режим = РежимБлокировкиДанных.Исключительный;
	ЭлементБлокировки.ИсточникДанных = СписокНоменклатуры;
	ЭлементБлокировки.ИспользоватьИзИсточникаДанных("Номенклатура", "Номенклатура");
	Блокировка.Заблокировать();
	
	//{{КОНСТРУКТОР_ЗАПРОСА_С_ОБРАБОТКОЙ_РЕЗУЛЬТАТА
	// Данный фрагмент построен конструктором.
	// При повторном использовании конструктора, внесенные вручную изменения будут утеряны!!!
	
	Запрос = Новый Запрос;
	Запрос.Текст = 
		"ВЫБРАТЬ
		|	РасходнаяНакладнаяСписокНоменклатуры.Номенклатура КАК Номенклатура,
		|	СУММА(РасходнаяНакладнаяСписокНоменклатуры.Количество) КАК Количество
		|ПОМЕСТИТЬ ТЧ
		|ИЗ
		|	Документ.РасходнаяНакладная.СписокНоменклатуры КАК РасходнаяНакладнаяСписокНоменклатуры
		|ГДЕ
		|	РасходнаяНакладнаяСписокНоменклатуры.Ссылка = &Ссылка
		|	И РасходнаяНакладнаяСписокНоменклатуры.Номенклатура.ВидНоменклатуры = ЗНАЧЕНИЕ(Перечисление.ВидыНоменклатуры.Товар)
		|
		|СГРУППИРОВАТЬ ПО
		|	РасходнаяНакладнаяСписокНоменклатуры.Номенклатура
		|
		|ИНДЕКСИРОВАТЬ ПО
		|	Номенклатура
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|ВЫБРАТЬ
		|	ТЧ.Номенклатура,
		|	ТЧ.Количество КАК КоличествоДок,
		|	ЕСТЬNULL(ОстаткиНоменклатурыОстатки.КоличествоОстаток, 0) КАК КоличествоОстаток,
		|	ЕСТЬNULL(ОстаткиНоменклатурыОстатки.СуммаОстаток, 0) КАК СуммаОстаток,
		|	ТЧ.Номенклатура.Представление КАК НоменклатураПредставление
		|ИЗ
		|	ТЧ КАК ТЧ
		|		ЛЕВОЕ СОЕДИНЕНИЕ РегистрНакопления.ОстаткиНоменклатуры.Остатки(
		|				&МоментВремени,
		|				Склад = &Склад
		|					И Номенклатура В
		|						(ВЫБРАТЬ
		|							ДокТЧ.Номенклатура
		|						ИЗ
		|							ТЧ КАК ДокТЧ)) КАК ОстаткиНоменклатурыОстатки
		|		ПО ТЧ.Номенклатура = ОстаткиНоменклатурыОстатки.Номенклатура";
	
	Запрос.УстановитьПараметр("МоментВремени", МоментВремени());
	Запрос.УстановитьПараметр("Склад", Склад);
	Запрос.УстановитьПараметр("Ссылка", Ссылка);
	
	РезультатЗапроса = Запрос.Выполнить();
	
	ВыборкаДетальныеЗаписи = РезультатЗапроса.Выбрать();
	
	Пока ВыборкаДетальныеЗаписи.Следующий() Цикл
		Если ВыборкаДетальныеЗаписи.КоличествоДок > ВыборкаДетальныеЗаписи.КоличествоОстаток Тогда
			Сообщение = Новый СообщениеПользователю;
			Сообщение.Текст = 
			"ОПЕР.: по номенклатуре " + ВыборкаДетальныеЗаписи.НоменклатураПредставление + 
			" не хватает товара. Реально есть " + ВыборкаДетальныеЗаписи.КоличествоОстаток;
			Сообщение.Сообщить(); 				
			Отказ = Истина;
			Продолжить;
		КонецЕсли;
		Если не Отказ Тогда
			Движение = Движения.ОстаткиНоменклатуры.Добавить();
			Движение.ВидДвижения = ВидДвиженияНакопления.Расход;
			Движение.Период = Дата;
			Движение.Номенклатура = ВыборкаДетальныеЗаписи.Номенклатура;
			Движение.Склад = Склад;
			Движение.Количество = ВыборкаДетальныеЗаписи.КоличествоДок;
			Если ВыборкаДетальныеЗаписи.КоличествоДок = ВыборкаДетальныеЗаписи.КоличествоОстаток Тогда
				Движение.Сумма 		= ВыборкаДетальныеЗаписи.СуммаОстаток;
			Иначе
				Движение.Сумма 		= ?(ВыборкаДетальныеЗаписи.КоличествоОстаток=0,0,ВыборкаДетальныеЗаписи.КоличествоДок / ВыборкаДетальныеЗаписи.КоличествоОстаток * ВыборкаДетальныеЗаписи.СуммаОстаток);
			КонецЕсли;
		КонецЕсли;
	КонецЦикла;
	
	//}}КОНСТРУКТОР_ЗАПРОСА_С_ОБРАБОТКОЙ_РЕЗУЛЬТАТА


	
	
	
	
	
	//{{__КОНСТРУКТОР_ДВИЖЕНИЙ_РЕГИСТРОВ
	// Данный фрагмент построен конструктором.
	// При повторном использовании конструктора, внесенные вручную изменения будут утеряны!!!

	// регистр ОстаткиНоменклатуры Расход

	//}}__КОНСТРУКТОР_ДВИЖЕНИЙ_РЕГИСТРОВ
КонецПроцедуры
