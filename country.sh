#!/usr/bin/env bash
#              bash 4.1.5(1)     Linux Ubuntu 10.04           Date : 2012-08-11
#
# _______________|  country : look-up country ISO code or currency symbol.
#
#           Usage:  country  [term]  ["iso"|"fx"]
#                      where                "fx" is foreign exchange,
#                                     "iso" is the default option,
#                             term is case-insensitive regular expression.
#
#        Examples:  % country 'united states'
#                   US
#                   % country 'United States' fx
#                   USD
#                   % country us
#                   UNITED STATES
#                   % country usd
#                   US
#                   % country usd fx
#                   UNITED STATES
#
#    Dependencies:  awk


#  CHANGE LOG  get LATEST version from https://bitbucket.org/rsvp/gists/src
#
#  2012-01-15  First version depends on these FACTS:
#      - ISO country code has exactly TWO letters.
#           See ISO 3166-1: http://www.iso.org/iso/iso_3166_code_lists
#      - Currency symbol has exactly THREE letters.
#           See ISO 4217:   http://en.wikipedia.org/wiki/Currency_code
#      - EUR here designates EUROZONE where the Euro may be also
#           used by non-EU members: http://en.wikipedia.org/wiki/Eurozone
#      - No country has a full NAME of three letters or less.


#           _____ Prelims
set -u
#   ^ unbound (i.e. unassigned) variables shall be errors.
#           Example of default assignment:    arg1=${1:-'foo'}
set -e
#   ^ error checking :: Highly Recommended (caveat:  you can't check $? later).  
#
# _______________     ::  BEGIN  Script ::::::::::::::::::::::::::::::::::::::::


term=${1:-'United States'}
term=${term^^}
#          uppper case conversion
termlen=${#term}
arg2=${2:-'iso'}


outf='/dev/shm/country-out.tmp'
tmpf='/dev/shm/country.tmp'

#   Write to TMP FILE data on 249 countries:
cat - > $tmpf <<EOHereDoc
AF@AFGHANISTAN@AFN
AX@ALAND ISLANDS
AL@ALBANIA
DZ@ALGERIA
AS@AMERICAN SAMOA
AD@ANDORRA@EUR
AO@ANGOLA
AI@ANGUILLA
AQ@ANTARCTICA
AG@ANTIGUA AND BARBUDA
AR@ARGENTINA@ARS
AM@ARMENIA
AW@ARUBA
AU@AUSTRALIA@AUD
AT@AUSTRIA@EUR
AZ@AZERBAIJAN
BS@BAHAMAS
BH@BAHRAIN
BD@BANGLADESH
BB@BARBADOS
BY@BELARUS
BE@BELGIUM@EUR
BZ@BELIZE
BJ@BENIN
BM@BERMUDA
BT@BHUTAN
BO@BOLIVIA
BQ@BONAIRE
BA@BOSNIA AND HERZEGOVINA
BW@BOTSWANA
BV@BOUVET ISLAND
BR@BRAZIL@BRL
IO@BRITISH INDIAN OCEAN TERRITORY
BN@BRUNEI DARUSSALAM
BG@BULGARIA
BF@BURKINA FASO
BI@BURUNDI
KH@CAMBODIA
CM@CAMEROON@XAF
CA@CANADA@CAD
CV@CAPE VERDE
KY@CAYMAN ISLANDS@KYD
CF@CENTRAL AFRICAN REPUBLIC@XAF
TD@CHAD@XAF
CL@CHILE
CN@CHINA@CNY
CX@CHRISTMAS ISLAND
CC@COCOS KEELING ISLANDS
CO@COLOMBIA
KM@COMOROS
CG@CONGO@XAF
CK@COOK ISLANDS
CR@COSTA RICA
CI@COTE D'IVOIRE
HR@CROATIA
CU@CUBA
CW@CURACAO
CY@CYPRUS@EUR
CZ@CZECH REPUBLIC
DK@DENMARK@DKK
DJ@DJIBOUTI
DM@DOMINICA
DO@DOMINICAN REPUBLIC
EC@ECUADOR
EG@EGYPT@EGP
SV@EL SALVADOR
GQ@EQUATORIAL GUINEA
ER@ERITREA
EE@ESTONIA@EUR
ET@ETHIOPIA
FK@FALKLAND ISLANDS MALVINAS
FO@FAROE ISLANDS
FJ@FIJI
FI@FINLAND@EUR
FR@FRANCE@EUR
GF@FRENCH GUIANA
PF@FRENCH POLYNESIA@XPF
TF@FRENCH SOUTHERN TERRITORIES
GA@GABON@XAF
GM@GAMBIA
GE@GEORGIA
DE@GERMANY@EUR
GH@GHANA
GI@GIBRALTAR@GIP
GR@GREECE@EUR
GL@GREENLAND@DKK
GD@GRENADA
GP@GUADELOUPE
GU@GUAM
GT@GUATEMALA
GG@GUERNSEY
GN@GUINEA
GW@GUINEA-BISSAU
GY@GUYANA
HT@HAITI
HM@HEARD MCDONALD ISLANDS@AUD
HN@HONDURAS
HK@HONG KONG@HKD
HU@HUNGARY
IS@ICELAND
IN@INDIA@INR
ID@INDONESIA
IR@IRAN@IRR
IQ@IRAQ
IE@IRELAND@EUR
IM@ISLE OF MAN@GBP
IL@ISRAEL@ILS
IT@ITALY@EUR
JM@JAMAICA@JMD
JP@JAPAN@JPY
JE@JERSEY
JO@JORDAN
KZ@KAZAKHSTAN
KE@KENYA
KI@KIRIBATI
KP@NORTH KOREA@KPW
KR@SOUTH KOREA@KRW
XK@KOSOVO@EUR
KW@KUWAIT
KG@KYRGYZSTAN
LA@LAOS
LV@LATVIA
LB@LEBANON@LBP
LS@LESOTHO
LR@LIBERIA
LY@LIBYA
LI@LIECHTENSTEIN@CHF
LT@LITHUANIA
LU@LUXEMBOURG@EUR
MO@MACAO
MK@MACEDONIA
MG@MADAGASCAR
MW@MALAWI
MY@MALAYSIA
MV@MALDIVES
ML@MALI
MT@MALTA@EUR
MH@MARSHALL ISLANDS
MQ@MARTINIQUE
MR@MAURITANIA
MU@MAURITIUS
YT@MAYOTTE
MX@MEXICO@MXN
FM@MICRONESIA
MD@MOLDOVA
MC@MONACO@EUR
MN@MONGOLIA@MNT
ME@MONTENEGRO@EUR
MS@MONTSERRAT
MA@MOROCCO@MAD
MZ@MOZAMBIQUE
MM@MYANMAR
NA@NAMIBIA
NR@NAURU@AUD
NP@NEPAL
NL@NETHERLANDS@EUR
NC@NEW CALEDONIA@XPF
NZ@NEW ZEALAND@NZD
NI@NICARAGUA
NE@NIGER
NG@NIGERIA@NGN
NU@NIUE
NF@NORFOLK ISLAND
MP@NORTHERN MARIANA ISLANDS
NO@NORWAY@NOK
OM@OMAN
PK@PAKISTAN@PKR
PW@PALAU
PS@PALESTINIAN TERRITORY
PA@PANAMA
PG@PAPUA NEW GUINEA
PY@PARAGUAY
PE@PERU
PH@PHILIPPINES@PHP
PN@PITCAIRN
PL@POLAND@PLN
PT@PORTUGAL@EUR
PR@PUERTO RICO@USD
QA@QATAR
RE@REUNION
RO@ROMANIA
RU@RUSSIA@RUB
RW@RWANDA
BL@SAINT BARTHELEMY
SH@SAINT HELENA
KN@SAINT KITTS AND NEVIS
LC@SAINT LUCIA
MF@SAINT MARTIN FRENCH
PM@SAINT PIERRE AND MIQUELON
VC@SAINT VINCENT AND GRENADINES
WS@SAMOA
SM@SAN MARINO@EUR
ST@SAO TOME AND PRINCIPE
SA@SAUDI ARABIA@SAR
SN@SENEGAL
RS@SERBIA
SC@SEYCHELLES
SL@SIERRA LEONE
SG@SINGAPORE@SGD
SX@SINT MAARTEN DUTCH
SK@SLOVAKIA@EUR
SI@SLOVENIA@EUR
SB@SOLOMON ISLANDS
SO@SOMALIA
ZA@SOUTH AFRICA@ZAR
GS@SOUTH GEORGIA AND SOUTH SANDWICH ISLANDS
SS@SOUTH SUDAN
ES@SPAIN@EUR
LK@SRI LANKA
SD@SUDAN
SR@SURINAME
SJ@SVALBARD AND JAN MAYEN
SZ@SWAZILAND
SE@SWEDEN@SEK
CH@SWITZERLAND@CHF
SY@SYRIA
TW@TAIWAN@TWD
TJ@TAJIKISTAN
TZ@TANZANIA
TH@THAILAND@THB
TL@TIMOR-LESTE
TG@TOGO
TK@TOKELAU
TO@TONGA
TT@TRINIDAD AND TOBAGO
TN@TUNISIA@TND
TR@TURKEY@TRY
TM@TURKMENISTAN
TC@TURKS AND CAICOS ISLANDS
TV@TUVALU
UG@UGANDA
UA@UKRAINE
AE@UNITED ARAB EMIRATES@AED
GB@UNITED KINGDOM@GBP
US@UNITED STATES@USD
UM@U.S. MINOR OUTLYING ISLANDS
UY@URUGUAY
UZ@UZBEKISTAN
VU@VANUATU
VA@VATICAN HOLY SEE@EUR
VE@VENEZUELA
VN@VIETNAM@VND
VG@VIRGIN ISLANDS BRITISH
VI@VIRGIN ISLANDS U.S.@USD
WF@WALLIS AND FUTUNA@XPF
EH@WESTERN SAHARA
YE@YEMEN
ZM@ZAMBIA
ZW@ZIMBABWE@ZWL
X1@GOLD@XAU
X2@SILVER@XAG
X3@PLATINUM@XPT
X4@SDR SPECIAL DRAWING RIGHTS@XDR
EOHereDoc

#  N.B. -  the last several entries (of form Xi where i=integer) 
#  are obviously not countries but included for sake of 
#  completeness for foreign exchange purposes.


#  Length of first argument term determines appropriate action;
#  where awk matches and prints the appropriate fields.
#              -F@ specifies field separator.

case $termlen in 
     
     1) :                                    > $outf  ;;
        #  doing nothing, so size zero file.

     2) if [ $arg2 = 'iso' ] ; then 
           awk -F@ "\$1 ~ /$term/ {print \$2}" $tmpf 
        else
           awk -F@ "\$1 ~ /$term/ {print \$3}" $tmpf 
        fi                                   > $outf  ;;

     3) if [ $arg2 = 'iso' ] ; then 
           awk -F@ "\$3 ~ /$term/ {print \$1}" $tmpf 
        else
           awk -F@ "\$3 ~ /$term/ {print \$2}" $tmpf 
        fi                                   > $outf  ;;

     *) if [ $arg2 = 'iso' ] ; then 
           awk -F@ "\$2 ~ /$term/ {print \$1}" $tmpf 
        else
           awk -F@ "\$2 ~ /$term/ {print \$3}" $tmpf 
        fi                                   > $outf  ;;

esac



#  display OUTPUT if non-zero size, otherwise generate error message:
#          remember to clean-up...
if [ -s  $outf ] ; then 
     cat $outf
     rm -f  $tmpf  $outf
else
     echo " !!  ${0##*/}: NULL response; check arguments and data."  1>&2
     rm -f  $tmpf  $outf
     exit 113
fi


exit 0
# _______________ EOS ::  END of Script ::::::::::::::::::::::::::::::::::::::::

#  vim: set fileencoding=utf-8 ff=unix tw=78 ai syn=sh :
