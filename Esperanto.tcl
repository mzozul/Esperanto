#!/usr/bin/wish

# Пакет для доступа к андроид-функциям
package require Borg 

package require Img
package require snack

package require sqlite3

# Окно приложения на весь экран
wm attribute . -fullscreen 1

# <Android> Портретная ориентация экрана 
#borg screenorientation portrait

# Цвет фона приложения
. config -bg green

#
#
# -----Работа с базой данных------
#
#

#Открыть базу
proc OpenBase {path} {
# Открыть файл базы данных
				sqlite3 db [file join [file dirname $path] default.sqlite]
}

proc CreateTable {nameBase nameTable args} {
  
		$nameBase eval "CREATE TABLE IF NOT EXISTS $nameTable (id INTEGER PRIMARY KEY, [join $args ,])"
}

# Вставка записи в таблицу tableForInsert базы данных nameBase строки из аргументов
proc InsertInTable {nameBase tableForInsert args} {
		set i 0

		foreach temp $args {
				if {$i % 2 == 0} {
						lappend nameField $temp
				} else {
						lappend valueField $temp
				}
				incr i
		}
	
		$nameBase eval "INSERT INTO $tableForInsert ([join $nameField ,]) VALUES ([join $valueField ,])"
}

# Возвращает перевод для слова word (на Эсперанто) из базы данных nameBase на язык lang
proc ReturnWordFromBase {nameBase lang word} {
		set zapros "SELECT $lang\_Text.date FROM $lang\_Text, Picture WHERE (($lang\_Text.picture_ID=Picture.id) AND (Picture.date = \"$word\"))"
				
		return [$nameBase eval $zapros]
}

# Перезаписывает 
proc WriteWordToBase {nameBase lang word} {
		set currentWordEO [.holst itemcget textEO -text]
		
		if { [lindex [ReturnWordFromBase $nameBase $lang $word] 0] == ""} {
#				tk_messageBox -message "Запись пуста! вносим данные"
		} else {
#				tk_messageBox -message "Запись существует! изменяем данные"
		}
		set zapros "UPDATE $lang\_Text SET date=\"$word\" WHERE picture_id = (SELECT id FROM Picture WHERE date = \"[string map {ĝ gx ŝ sx ĉ cx ĵ jx ŭ ux} $currentWordEO]\")"

		$nameBase eval $zapros
}


#
#
# ----------Создание UI-------------
#
#

proc CreateUI {} {
 
		global  currentPath currentPicture
		canvas .holst -bg black

		set buttonFrame [frame .buttons -bg blue]

		set but1 [button $buttonFrame.button1 -text "Варианты"]
		 #-command {WriteWordToBase db RU $tempText}]

		set but2 [button $buttonFrame.button2 -text "Пред." -command {DeletePicture; incr currentPicture -1; NextRecord  $currentPath $currentPicture "RU"}]

		set but3 [button $buttonFrame.button3 -text "След." -command {DeletePicture; incr currentPicture; NextRecord  $currentPath $currentPicture "RU"}]

		set but4 [button $buttonFrame.button4 -text "Выход" -command {db close; exit}]

		pack $but1 $but2 $but3 $but4 -side left -fill x -expand true
		pack $buttonFrame -side bottom -fill x
		pack .holst -side top -fill both -expand true
		
		update
		CreateButtonOnHolst .holst 10 60 "EOconfig" 
		CreateButtonOnHolst .holst 10 1060 "RUconfig"		
}
# Отобразить картинку с полным именем currentPictureName
proc NextPicture {currentPictureName} {
  set img [image create photo]
  $img read $currentPictureName
  .holst create image 360 550 -image $img -tag "image" -anchor n
}

#очистить холст
proc DeletePicture {} {
  .holst delete "image"
  .holst delete "textEO"
  .holst delete "textRU"
  .holst delete "editTextRU"
}
 
# Включить голос с полным именем currentVoiceName
proc NextVoice {currentVoiceName} {
		global temp
		set temp 0
		snack::audio stop
  set voice [snack::sound]
  $voice configure -load $currentVoiceName
  $voice play -command "set temp 1; $voice destroy"
  vwait temp
}

#Возвращает полное имя картинки из папки currentPath, расположенной в ней по порядку на numberOfCurrentPicture месте
proc ReturnNameOfCurrentPicture {currentPath numberOfCurrentPicture} { 
  return [file join $currentPath "images" [lindex [glob -directory [file join $currentPath "images"] -tails -- *] $numberOfCurrentPicture]]
}

# Возвращает корректный номер изображения из папки path, если number выходит за пределы сушествующего списка файлов  
proc ReturnCorrectNumberPicture {path number} {
		
		set x $number
		if {$number == [llength [glob -directory [file join $path "images"] -tails -- *]]} {
				set x 0
		}
		
		if {$number < 0} {
				set x [llength [glob -directory [file join $path "images"] -tails -- *]]
				incr x -1
		}
		return $x
}

proc PrintText {holst textForOutPut lang y} {


		$holst create text [expr [winfo width $holst]/2] $y -text [string map {gx ĝ sx ŝ cx ĉ jx ĵ ux ŭ} $textForOutPut] -tag "text$lang" -justify center -fill white -width [expr [winfo width $holst] - 170] -anchor n  -font [font create -family Helvetica -size 18]

}

# Выводит картинку, звук в соответствии с номером number из папки path
proc NextRecord {path number lang} {
		global modeVoiceRU modeTextRU
		
		set date [file tail [file rootname [ReturnNameOfCurrentPicture $path [ReturnCorrectNumberPicture $path $number]]]]
		
		PrintText .holst $date "EO" 50
	
		if {$modeTextRU} {
	
				PrintText .holst  [ReturnWordFromBase db $lang $date] $lang 1060
		}
		
		NextPicture  [ReturnNameOfCurrentPicture $path [ReturnCorrectNumberPicture $path $number]]
		update
		
		NextVoice [file join $path "sounds" "EO" [join [glob -directory [file join $path "sounds" "EO"] -tails -nocomplain --  [file tail [file rootname [ReturnNameOfCurrentPicture $path [ReturnCorrectNumberPicture $path $number]]]].wav]]]
		
		if {$modeVoiceRU} {
				NextVoice [file join $path "sounds" $lang [join [glob -directory [file join $path "sounds" $lang] -tails -nocomplain --  [file tail [file rootname [ReturnNameOfCurrentPicture $path [ReturnCorrectNumberPicture $path $number]]]].wav]]]
		}
}

# Установить фоновую картинку
proc SetBackgraundPicture {} {
		#		image create photo newFotoForBackgraund -width [winfo width .holst] -height [winfo height .holst]
		
#		newFotoForBackgraund copy oldFotoForBackgraund -to 0 0 [winfo width .holst] [winfo height .holst] -shrink
		
#		.holst create image 0 0 -image newFotoForBackgraund -anchor nw
}

# Создание кнопки на холсте holst
proc CreateButtonOnHolst {holst x y tag} {
		$holst create oval $x $y [expr ($x+75)] [expr ($y+75)] -fill green -tag $tag 
}

#Изменить состояние кнопки на холсте
proc SetModeVoice {holst tag} {
		global modeVoiceRU
		set modeVoiceRU [expr {!$modeVoiceRU}]
		if {!$modeVoiceRU} {
				$holst itemconfigure $tag -fill red
		} else {
				$holst itemconfigure $tag -fill green
		}
}


# Редактирование записи перевода фразы 
proc EditText {holst tagOnHolst} {
		#Сохраняем текст в переменной и очищаем поле
		global tempFrame holst2 tagOnHolst2 tempText
		set holst2 $holst
		set tagOnHolst2 $tagOnHolst
		set tempText [$holst2 itemcget $tagOnHolst -text]
		$holst dchars $tagOnHolst 0 end
		
		# Отображаем окно для ввода новой строки с кнопкой ок
		set tempFrame [frame $holst.tempFrame]
		
		frame $tempFrame.tempFrameForButton
		
		$holst create window 0 0 -anchor nw -window $tempFrame -width [winfo width $holst]
		
		label $tempFrame.label -text "New translation:"
		
		entry $tempFrame.tempFrameForButton.entry  -textvariable tempText
		button $tempFrame.tempFrameForButton.buttonOK -text "OK" -command {$holst2 insert $tagOnHolst2 0 $tempText; sdltk textinput off;destroy $tempFrame; WriteWordToBase "db" "RU" [$holst2 itemcget textRU -text]}
		button $tempFrame.tempFrameForButton.buttonCancel -text "Cancel" -command {sdltk textinput off; destroy $tempFrame}
		
		pack $tempFrame.tempFrameForButton.buttonCancel $tempFrame.tempFrameForButton.entry $tempFrame.tempFrameForButton.buttonOK -side left -fill x -expand true
		pack $tempFrame.label $tempFrame.tempFrameForButton -side top -fill both -expand true
		# Отображаем клавиатуру
		sdltk textinput on 
		# Устанавливаем фокус ввода в поле ввода
		focus $tempFrame.tempFrameForButton.entry
		$tempFrame.tempFrameForButton.entry selection range 0 end

}

#
#
# -------Основная программа-------
#
#

		global currentPicture
		set currentPicture 1
		
		global modeVoiceRu modeTextRU
		set modeVoiceRU 1
		set modeTextRU 1
# Путь к медиа на локальной машине
		set currentPath [file join [file dirname [info script]] "media"]

# Открыть файл базы данных	
		OpenBase [info script]
		CreateTable db Picture date autor_ID
		
		CreateTable db EO_Voice dataTime picture_ID autor_ID
		
		CreateTable db RU_Text date dataTime picture_ID autor_ID
		CreateTable db RU_Voice dataTime RU_Text_ID autor_ID
		
		CreateTable db autor fio 

# Создание UI
		CreateUI
		
		
		NextRecord  $currentPath $currentPicture "RU"

# Связывание нажатия ЛКМ по пиктограмме с тегом RUconfig и процедуры вкл/выкл звука русского языка
	.holst bind RUconfig <Button-1> {SetModeVoice .holst RUconfig}
	
	.holst bind textRU <Button-1> {CreateButtonOnHolst .holst [expr [winfo width .holst]-90] 1060 "editTextRU"}
	
	.holst bind editTextRU <Button-1> {EditText .holst textRU}
		
#
#
# --- Конец основной программы	---
#
#
		
		
		
# Временная процедура для записи в БД
proc tempRecordInBase {nameBase} {
		tk_messageBox -message "Insert in Base"
		set tempTime [clock format [clock seconds] -format "%d.%m.%Y %T"]
		tk_messageBox -message $tempTime
		set temp [$nameBase eval "SELECT id FROM Picture"]
		tk_messageBox -message $temp
		foreach x $temp {
				$nameBase eval "INSERT INTO EO_Voice (dataTime,picture_ID, autor_ID) VALUES (\"$tempTime\",\"$x\",1)"
				$nameBase eval "INSERT INTO RU_Text (dataTime,picture_ID, autor_ID) VALUES (\"$tempTime\",\"$x\",1)"
				$nameBase eval "INSERT INTO RU_Voice (dataTime,RU_Text_ID, autor_ID) VALUES (\"$tempTime\",\"$x\",1)"
		}
		tk_messageBox -message "Insert OK"
}