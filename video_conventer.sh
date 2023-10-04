#!/bin/bash
#EasyVideo 1.0 - Created by Michał Tarnacki ()
#Last update 30.04.2022
# Name EasyVideo
# Author Michal Tarnacki ()
# Created On 9.04.2022
# Last Modified By : Michał Tarnacki ()
# Last Modified On : 9.04.2022
# Version : 1.0
#
# Description :
#
# Skrypt wykorzystuje FFmpeg 5.0 "Lorentz" w celu konwersji i modyfikacji
# plików wideo.
# Umożliwia też stworzenie nowych plików w innych formatach na podstawie
# załączonego pliku.
# Do okienkowej obsługi skryptu zostało użyte narzędzie YAD - Yet another
# dialog.
# Jest ono bardziej rozbudowane niż Zenity - pozwala na większą personalizację
# wyglądu okna i jego treści.
#
# Skrypt pozwala na:
# zwykłą konwersję np. z formatu mp4 na mkv
# kompresję poprzez zmniejszenie bitrate'u lub liczby klatek
# zmianę wymiarów filmu np. zmianę z 4K na FHD
# [^powyższe opcje dostępne są jednocześnie]
#
# Ponadto:
# stworzenie nowego pliku wideo poprzez wycięcie fragmentu z zadanego pliku
# stworzenie pliku audio poprzez wycięcie z filmu dźwięku
# stworzenie pliku gif na podstawie przesłanego wideo #
# Wybór pliku odbywa się przez wskazanie go za pomocą okna.
# Lokalizacja pliku wyjściowego może być domyślna (w miejscu w którym
# znajduje się oryginalny plik) lub też wybrana przez użytkownika. #
# Licensed under GPL (see /usr/share/common-licenses/GPL for more details
# or contact # the Free Software Foundation for a copy)

ipcrm --all=shm
function pomoc() {
  yad --fixed --skip-taskbar --image-on-top --text-align center --no-buttons --width 300 --height 300 --borders 10 --center --title "EasyVideo" \
    --text "
  Description :
    Skrypt wykorzystuje FFmpeg 5.0 "Lorentz" w celu konwersji i modyfikacji
    plików wideo.
    Umożliwia też stworzenie nowych plików w innych formatach na podstawie
    załączonego pliku.
    Do okienkowej obsługi skryptu zostało użyte narzędzie YAD - Yet another
    dialog.
    Jest ono bardziej rozbudowane niż Zenity - pozwala na większą personalizację
   wyglądu okna i jego treści.
  Skrypt pozwala na:
    zwykłą konwersję np. z formatu mp4 na mkv
    kompresję poprzez zmniejszenie bitrate'u lub liczby klatek
    zmianę wymiarów filmu np. zmianę z 4K na FHD
    [^powyższe opcje dostępne są jednocześnie]

  Ponadto:
    stworzenie nowego pliku wideo poprzez wycięcie fragmentu z zadanego pliku
    stworzenie pliku audio poprzez wycięcie z filmu dźwięku
    stworzenie pliku gif na podstawie przesłanego wideo
    Wybór pliku odbywa się przez wskazanie go za pomocą okna.
    Lokalizacja pliku wyjściowego może być domyślna (w miejscu w którym
    znajduje się oryginalny plik) lub też wybrana przez użytkownika.
    " --text-align center
}
function info(){
  yad --fixed --skip-taskbar --image-on-top --text-align center --no-buttons --width 300 --height 300 --borders 10 --center --title "EasyVideo" \
    --text "
    Author : Michał Tarnacki
    Name: EasyVideo

    Created On : 9.04.2022
    Last Modified By : Michał Tarnacki
    Last Modified On : 9.04.2022
    Version : 1.0

    Licensed under GPL (see /usr/share/common-licenses/GPL for more details
    or contact # the Free Software Foundation for a copy)
    " --text-align center
}
while getopts hvf:q OPT; do
  case $OPT in
    h) pomoc;;
    v) info;;
    *) exit;;
  esac
done

PLIK=""

function brakZaznaczonegoPlikuMenu() {
  PLIKTMP=$(yad --fixed --skip-taskbar --image-on-top --text-align center --buttons-layout center --exit-on-drop 1 --width 300 --height 300 --borders 10 --center  --dnd  --title "EasyVideo" \
    --button="Wybierz ręcznie:2" \
    --text "Upuść tutaj plik:")
}
function zaznaczonyPlikMenu() {
  NAZWAPLIKU=$(basename "$PLIK")
  PLIKTMP=$(yad --fixed --skip-taskbar --image-on-top --text-align center --buttons-layout center --exit-on-drop 1 --width 300 --height 300 --borders 10 --center  --dnd  --title "EasyVideo" \
    --button="Cofnij:1" \
    --button="Wybierz ręcznie:2" \
    --button="Potwierdź:3" \
    --image "file.png" \
    --text "Wybrany plik:
    $NAZWAPLIKU" --text-align left)
}
function wybierzRecznieMenu(){
  WYSWIETLNAZWE=
  if [[ -z $NAZWAPLIKU ]]; then
     WYSWIETLNAZWE= ; else WYSWIETLNAZWE="Wybrany plik: $NAZWAPLIKU" ; fi
  PLIKTMP=$(yad --fixed --skip-taskbar --image-on-top --text-align center --buttons-layout center --width 300 --height 300 --borders 10 --center  --file  --title "EasyVideo" \
    --button="Anuluj:1" \
    --button="Potwierdź:2" \
    --text "$WYSWIETLNAZWE" --text-align center)
}
function zlyPlikMenu(){
  yad --fixed --skip-taskbar --image-on-top --text-align center --buttons-layout center --width 300 --height 300 --borders 10 --center  --title "EasyVideo" \
    --button="Powrot:0" \
    --image "warning.png" \
    --text "Plik:
    $NAZWAPLIKU
    ma niepoprawny format" --text-align center
}
function wybierzFormatMenu(){
  U1=$(yad --list --ellipsize=end --column=Wybierz --fixed --skip-taskbar --buttons-layout center --width 300 --height 300 --button="Anuluj:1" --button="Potwierdź:2" \
  --borders 10 --center --title "EasyVideo" --text "$NAZWAPLIKU" --text-align center \
    mp4 \
    avi \
    webm \
    ogg \
    wmv \
    gif \
    mp3 \
    )
    Zmienna=$?
    US1=$(echo $U1 | cut -d "|" -f 1)
    case $Zmienna in
      "1")
      ;;
      "2")
      if [[ $US1 == "mp3" ]]; then
        ustawDlugosc
      else
        ustawBitrateILiczbeKlatekMenu
      fi
      ;;
      "252")
    esac
}
function blad(){
  yad --fixed --skip-taskbar --image-on-top --text-align center --buttons-layout center --width 300 --height 300 --borders 10 --center  --title "EasyVideo" \
    --button="Powrot:0" \
    --image "warning.png" \
    --text "$ERROR" --text-align center
}
function ustawBitrateILiczbeKlatekMenu(){
  WYJSCIE="NIE"
  echo $US2
  if [ -z $US2 ]; then US2=$BITRATE; fi
  if [ -z $US3 ]; then US3=$FPS; fi
  while [ $WYJSCIE == "NIE" ];
  do
    WYJSCIE="TAK"
    U2=$(yad --form --fixed --skip-taskbar --buttons-layout center --width 300 --height 300 --button="Anuluj:1" \
    --button="Cofnij:3" --button="Potwierdź:2" \
    --borders 10 --center --title "EasyVideo" --text "$NAZWAPLIKU" --text-align center \
      --text="
      " --text-align center \
      --field="Bitrate (Kbps):" "$US2" \
      --field="Liczba klatek na sekunde:" "$US3" \
      )
      Zmienna=$?
      echo $Zmienna
      if [ $Zmienna -ne "1" ] && [ $Zmienna -ne "3" ] && [ $Zmienna -ne "252" ] ; then
        US2=$(echo $U2 | cut -d "|" -f 1)
        US3=$(echo $U2 | cut -d "|" -f 2)
        if [[ ! $US2 =~ (^[0-9]{1,}\.[0-9]{1,}$)|(^[0-9]{1,}$) ]]; then
          ERROR="Podano zły format:
          bitrate, wpisz w formacie xx.yy"
          blad
          WYJSCIE="NIE"
          US2=$BITRATE
        fi
        test1=$(echo $US2 '>' $BITRATE | bc -l)
        test2=$(echo $US2 '<' 1 | bc -l)
        if [ "$test1" -eq "1" ] || [ "$test2" -eq "1" ]; then
          ERROR="Niepoprawna wartosc bitrate"
          blad
          WYJSCIE="NIE"
          US2=$BITRATE
        fi
        if [[ ! $US3 =~ (^[0-9]{1,}\.[0-9]{1,}$)|(^[0-9]{1,}$) ]]; then
          ERROR="Podano zły format:
          liczby klatek, wpisz w formacie xx.yy"
          blad
          WYJSCIE="NIE"
          US3=$FPS
        fi
        test1=$(echo $US3 '>' $FPS | bc -l)
        test2=$(echo $US3 '<=' 0 | bc -l)
        if [ "$test1" -eq "1" ] || [ "$test2" -eq "1" ]; then
          ERROR="Niepoprawna wartosc liczby klatek"
          blad
          WYJSCIE="NIE"
          US3=$FPS
        fi
      fi
    done
#US2 US3
    case $Zmienna in
      "1")
      ;;
      "2")
      ustawRozdzielczoscMenu
      ;;
      "3")
      wybierzFormatMenu
      ;;
      "252")
    esac
}
function wpiszRozmaryMenu(){
  WYJSCIE="NIE"
  while [ $WYJSCIE == "NIE" ];
  do
    WYJSCIE="TAK"
    U3=$(yad --form --fixed --skip-taskbar --buttons-layout center --width 300 --height 300 --button="Anuluj:1" \
    --button="Cofnij:3" --button="Potwierdź:2" \
    --borders 10 --center --title "EasyVideo" --text "$NAZWAPLIKU" --text-align center \
      --text="
      " --text-align center \
      --field="Szerokosc:" "$US8" \
      --field="Wysokosc:" "$US9" \
      )
    Zmienna=$?
    if [ $Zmienna -ne "1" ] && [ $Zmienna -ne "3" ] && [ $Zmienna -ne "252" ]; then
      echo $U3
      US8=$(echo $U3| cut -d "|" -f 1)
      US9=$(echo $U3| cut -d "|" -f 2)

      if [[ ! $US8 =~ ^[0-9]{1,}$ ]]; then
        ERROR="Podano zły format:
        szerokosci, wpisz liczbe calkowita"
        blad
        WYJSCIE="NIE"
        US8=
      else
        test=$(echo $US8 '<=' 0 | bc -l)
        if [ "$test" -eq "1" ]; then
          ERROR="Niepoprawna wartosc szerokosci"
          blad
          WYJSCIE="NIE"
          US8=
        fi
      fi
      if [[ ! $US9 =~ ^[0-9]{1,}$ ]]; then
        ERROR="Podano zły format:
        wysokosci, wpisz liczbe calkowita"
        blad
        WYJSCIE="NIE"
        US9=
      else
        test2=$(echo $US9 '<=' 0 | bc -l)
        if [ "$test2" -eq "1" ]; then
          ERROR="Niepoprawna wartosc wysokosci"
          blad
          WYJSCIE="NIE"
          US9=
        fi
      fi
    fi
  done
  case $Zmienna in
    "1")
    ;;
    "2")
    ;;
    "3")
    ;;
    "252")
    ;;
  esac
}
#US8 US9
function ustawRozdzielczoscMenu(){
  WYJSCIE="NIE"
  while [ $WYJSCIE == "NIE" ];
  do
    WYJSCIE="TAK"
    U3=$(yad --list --column=Wybierz --column=Szerokosc --column=Wysokosc --column=Proporcje --fixed --skip-taskbar \
     --buttons-layout center --width 300 --height 300 --button="Anuluj:1" --button="Cofnij:3" --button="Potwierdź:2" \
      --borders 10 --center --title "EasyVideo" --text "$NAZWAPLIKU" --text-align center \
      Bez\ zmiany \  \  \  \
      4K 3840 2160 16:9 \
      FullHD 1920 1080 16:9 \
      CinemaTV 2560 1080 21:9 \
      HD 1280 720 19:9 \
      DVD 720 576 5:3 \
      Niestandardowe \ $US8 \ $US9 \  \
      )
      Zmienna=$?
      if [ $Zmienna -ne "1" ] && [ $Zmienna -ne "3" ] && [ $Zmienna -ne "252" ]; then
        US4=$(echo $U3| cut -d "|" -f 1)
        US5=$(echo $U3| cut -d "|" -f 2)
        US6=$(echo $U3| cut -d "|" -f 3)
        US7=$(echo $U3| cut -d "|" -f 4)
        if [ $Zmienna == "0" ] && [ $US4 == "Niestandardowe" ]; then
          wpiszRozmaryMenu
          WYJSCIE="NIE"
        elif [ $Zmienna == "0" ]; then
          WYJSCIE="NIE"
        elif [[ $Zmienna == "2" ]] && [[ $US4 == "Niestandardowe" ]]; then
          if [ -z $US5 ] || [ -z $US6 ]; then
            ERROR="Nie wszystkie wymiary zostały podane"
            blad
            WYJSCIE="NIE"
          else
            US5=$US8
            US6=$US9
          fi
        fi
      fi
  done
  case $Zmienna in
    "1")
    ;;
    "2")
    ustawDlugosc
    ;;
    "3")
    ustawBitrateILiczbeKlatekMenu
    ;;
    "252")
  esac
}
function ustawDlugosc(){
  WYJSCIE="NIE"
  if [ -z $US10 ]; then US10="0:00:00"; fi
  if [ -z $US11 ]; then US11=$DLUGOSC; fi
  while [ $WYJSCIE == "NIE" ];
  do
    WYJSCIE="TAK"
    U4=$(yad --fixed --skip-taskbar \
     --buttons-layout center --width 300 --height 300 --button="Anuluj:1" --button="Cofnij:3" --button="Potwierdź:2" \
      --borders 10 --center --title "EasyVideo" --text "$NAZWAPLIKU" --text-align center --text="
      Podaj w formacie hh:mm:ss
      " --text-align center \
      --form \
      --field="Poczatek:" "$US10" \
      --field="Koniec:" "$US11" \
      )
      Zmienna=$?
      if [ $Zmienna -ne "1" ] && [ $Zmienna -ne "3" ] && [ $Zmienna -ne "252" ] ; then
        US10=$(echo $U4 | cut -d "|" -f 1)
        US11=$(echo $U4 | cut -d "|" -f 2)
        TMP1=$(echo $DLUGOSC | sed -e "s/://g")
        TMP2=$(echo $US11 | sed -e "s/://g")
        TMP3=$(echo $US10 | sed -e "s/://g")
        if [[ ! $US10 =~ ^[0-9]{1,}:[0-5][0-9]:[0-5][0-9]$ ]]; then
          ERROR="Podano zły format lub niepoprawna wartosc:
          czas poczatkowy"
          blad
          WYJSCIE="NIE"
          US10="0:00:00"
        else
          echo
        fi
        if [[ ! $US11 =~ ^[0-9]{1,}:[0-5][0-9]:[0-5][0-9]$ ]]; then
          ERROR="Podano zły format lub niepoprawna wartosc:
          czas koncowy"
          blad
          WYJSCIE="NIE"
          US11=$DLUGOSC
        else
          test=$(echo $TMP2 '>' $TMP1 | bc -l)
          if [ "$test" -eq "1" ]; then
            ERROR="Czas koncowy ponad dlugosc filmu"
            blad
            WYJSCIE="NIE"
            US11=$DLUGOSC
          fi
        fi
        echo $TMP2 $TMP3
        if [[ $US11 =~ ^[0-9]{1,}:[0-5][0-9]:[0-5][0-9]$ ]] && [[ $US10 =~ ^[0-9]{1,}:[0-5][0-9]:[0-5][0-9]$ ]]; then
          test=$(echo $TMP3 '>=' $TMP2 | bc -l)
          if [ "$test" -eq "1" ]; then
            ERROR="Czas poczatkowy przekracza lub jest równy koncowemu"
            blad
            WYJSCIE="NIE"
            US10="0:00:00"
          fi
        fi
      fi
    done
    case $Zmienna in
      "1")
      ;;
      "2")
      wybierzMiejsceDoceloweMenu
      ;;
      "3")
      if [[ $US1 == "mp3" ]]; then
        wybierzFormatMenu
      else
        ustawRozdzielczoscMenu
      fi
      ;;
      "252")
    esac
}
# Opcjonalne menu do opcji specjalych
# function opcjeSpecjalne() {
#   U5=$(yad --fixed --skip-taskbar \
#    --buttons-layout center --width 300 --height 300 --button="Anuluj:1" --button="Cofnij:3" --button="Potwierdź:2" \
#     --borders 10 --center --title "EasyVideo" --text "$NAZWAPLIKU" --text-align center --list  --column=Wybierz \
#     Brak \
#     Tylko\ dzwiek \
#     GIF \
#     )
#     Zmienna=$?
#     case $Zmienna in
#       "1")
#       ;;
#       "2")
#       U5=$(echo $U5 | cut -d "|" -f 1 )
#       wybierzMiejsceDoceloweMenu
#       ;;
#       "3")
#       ustawDlugosc
#       ;;
#       "252")
#     esac
# }

function wybierzMiejsceDoceloweMenu() {
  U6=$(yad --fixed --skip-taskbar \
   --buttons-layout center --width 300 --height 300 --button="Anuluj:1" --button="Cofnij:3" --button="Potwierdź:2" \
    --borders 10 --center --title "EasyVideo" --text "Wybierz miejsce docelowe" --text-align center --file --directory \
    )
    Zmienna=$?
    case $Zmienna in
      "1")
      ;;
      "2")
      stworzPlik
      ;;
      "3")
      ustawDlugosc
      ;;
      "252")
    esac
}

function pomyslnieSkonwertowano(){
  yad --fixed --skip-taskbar --image-on-top --text-align center --buttons-layout center --width 300 --height 300 --borders 10 --center  --title "EasyVideo" \
    --button="Powrot:0" \
    --image "ok.png" \
    --text "Konwersja się udała a plik zapisano jako:
    $NOWANAZWA
    " --text-align center
}

function stworzPlik() {
  # echo $U5 #specjalne opcje
  # echo $U6 #lokalizacja docelowa
  # echo $US1 #format
  # echo $US2 #bitrate
  # echo $US3 #liczba klatek
  # echo $US5 #szerokosc
  # echo $US6 #wysokosc
  # echo $US10 #poczatek
  # echo $US11 #koniec
  NOWANAZWA=$U6/EasyVideo$ID.$US1
  while [ -f "$NOWANAZWA" ]; do
    let "ID++"
    NOWANAZWA=$U6/EasyVideo$ID.$US1
  done
  SKALA=
  if [ ! -z $US6 ]; then
    SKALA="-vf scale=$US5:$US6,setdar=$US5/$US6"
  fi
  LICZBA=$(ffprobe -v error -select_streams v:0 -count_packets -show_entries stream=nb_read_packets -of csv=p=0 $PLIK)
  if [[ $US1 == "mp3" ]]; then
    stdbuf -i0 -o0 -e0 ffmpeg -i $PLIK -ss $US10 -to $US11 $NOWANAZWA \
     | stdbuf -i0 -o0 -e0 grep -Eo "^frame=[0-9]{1,}$" | stdbuf -i0 -o0 -e0 cut -d "=" -f 2 | \
      stdbuf -i0 -o0 -e0 sed "s/$/*100\/$LICZBA/" | stdbuf -i0 -o0 -e0 bc | yad --fixed --skip-taskbar --no-buttons --align center --auto-close \
        --width 300 --height 300 --image "progress.png" \
        --borders 10 --center --title "EasyVideo" --text "Trwa konwertowanie pliku" --text-align center --progress
        Zmienna=$?
  else
    stdbuf -i0 -o0 -e0 ffmpeg -i $PLIK -ss $US10 -to $US11 $SKALA -b:a $US2"k" -b:v $US2"k" -r $US3 -progress - -y $NOWANAZWA \
     | stdbuf -i0 -o0 -e0 grep -Eo "^frame=[0-9]{1,}$" | stdbuf -i0 -o0 -e0 cut -d "=" -f 2 | \
      stdbuf -i0 -o0 -e0 sed "s/$/*100\/$LICZBA/" | stdbuf -i0 -o0 -e0 bc | yad --fixed --skip-taskbar --no-buttons --align center --auto-close \
        --width 300 --height 300 --image "progress.png" \
        --borders 10 --center --title "EasyVideo" --text "Trwa konwertowanie pliku" --text-align center --progress
        Zmienna=$?
  fi
  pomyslnieSkonwertowano
  Zmienna=$?
  echo $US6
}

function coZrobicZPlikiemMenu(){
  DANE=$(ffprobe -i "$PLIK" -show_format -sexagesimal)
  DANEwS=$(ffprobe -i "$PLIK" -show_format)
  DLUGOSC=$(echo "$DANE" | grep -Eo "duration=[0-9]{1,}:[0-9]{2}:[0-9]{2}" | cut -d "=" -f 2)
  DLUGOSCwS=$(echo "$DANEwS" | grep -Eo "duration=[0-9]{1,}.[0-9]{1,}" | cut -d "=" -f 2)
  BITRATE=$(echo "$DANE" | grep -Eo "bit_rate=[0-9]{1,}" | cut -d "=" -f 2)
  BITRATE=$(echo "scale = 2 ; $BITRATE / 1000" | bc)
  FPS=$(ffprobe -i "$PLIK" -count_frames -v error -select_streams v:0 -show_entries stream=nb_read_frames -of default=nokey=1:noprint_wrappers=1)
  FPS=$(echo "scale = 2 ; $FPS / $DLUGOSCwS" | bc)
  US1=
  US2=
  US3=
  US4=
  US5=
  US6=
  US7=
  US8=
  US9=
  US10=
  US11=
  #Zmienne potrzebne do zebrania danych
  wybierzFormatMenu
}

while [ !$KONIEC ]
do
  if [[ -z $PLIK ]]; then
     brakZaznaczonegoPlikuMenu
  else
    zaznaczonyPlikMenu
  fi
  Zmienna=$?
  if [[ $PLIKTMP ]]; then
    PLIK=$PLIKTMP
  fi
  if [[ $Zmienna == "1" ]]; then
    PLIK=
    NAZWAPLIKU=
  elif [[ $Zmienna == "2" ]]; then
    wybierzRecznieMenu
    Zmienna=$?
    if [[ $PLIKTMP ]] && [[ $Zmienna == "2" || $Zmienna == "0" ]]; then
      PLIK=$PLIKTMP
    fi
  elif [[ $Zmienna == "3" ]]; then
    FORMAT=$(ffprobe -v quiet -show_entries format=format_name -of default=noprint_wrappers=1:nokey=1 "$PLIK")
    if [[ $FORMAT == "matroska,webm" || $FORMAT == "avi" || $FORMAT == "asf" || $FORMAT == "ogg" || $FORMAT == "mov,mp4,m4a,3gp,3g2,mj2" ]]; then
      coZrobicZPlikiemMenu
    else
      zlyPlikMenu
      Zmienna=$?
    fi
  elif [[ $Zmienna == "1" ]]; then
    echo "u"
  fi
  if [[ $Zmienna == "252" ]]; then
    break
  fi
done
