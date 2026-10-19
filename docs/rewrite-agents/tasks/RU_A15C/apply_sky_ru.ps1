$ErrorActionPreference = 'Stop'
$path = Join-Path $PSScriptRoot '..\..\..\..\next\apps\quiz_app\assets\quizipedia\catalog.json'
$catalog = Get-Content -Raw $path | ConvertFrom-Json

$genitive = @{
  And='Андромеды'; Ant='Насоса'; Aps='Райской Птицы'; Aql='Орла'; Aqr='Водолея'; Ara='Жертвенника'; Ari='Овна'; Aur='Возничего'; Boo='Волопаса'; Cae='Резца'; Cam='Жирафа'; Cap='Козерога'; Car='Киля'; Cas='Кассиопеи'; Cen='Центавра'; Cep='Цефея'; Cet='Кита'; Cha='Хамелеона'; Cir='Циркуля'; CMa='Большого Пса'; CMi='Малого Пса'; Cnc='Рака'; Col='Голубя'; Com='Волос Вероники'; CrA='Южной Короны'; CrB='Северной Короны'; Crt='Чаши'; Cru='Южного Креста'; Crv='Ворона'; CVn='Гончих Псов'; Cyg='Лебедя'; Del='Дельфина'; Dor='Золотой Рыбы'; Dra='Дракона'; Equ='Малого Коня'; Eri='Эридана'; For='Печи'; Gem='Близнецов'; Gru='Журавля'; Her='Геркулеса'; Hor='Часов'; Hya='Гидры'; Hyi='Южной Гидры'; Ind='Индейца'; Lac='Ящерицы'; Leo='Льва'; LMi='Малого Льва'; Lep='Зайца'; Lib='Весов'; Lup='Волка'; Lyn='Рыси'; Lyr='Лиры'; Men='Столовой Горы'; Mic='Микроскопа'; Mon='Единорога'; Mus='Мухи'; Nor='Наугольника'; Oct='Октанта'; Oph='Змееносца'; Ori='Ориона'; Pav='Павлина'; Peg='Пегаса'; Per='Персея'; Phe='Феникса'; Pic='Живописца'; Psc='Рыб'; PsA='Южной Рыбы'; Pup='Кормы'; Pyx='Компаса'; Ret='Сетки'; Scl='Скульптора'; Sco='Скорпиона'; Sct='Щита'; Ser='Змеи'; Sex='Секстанта'; Sge='Стрелы'; Sgr='Стрельца'; Tau='Тельца'; Tel='Телескопа'; TrA='Южного Треугольника'; Tri='Треугольника'; Tuc='Тукана'; UMa='Большой Медведицы'; UMi='Малой Медведицы'; Vel='Парусов'; Vir='Девы'; Vol='Летучей Рыбы'; Vul='Лисички'
}
$greek = @{Alp='Альфа';Bet='Бета';Gam='Гамма';Del='Дельта';Eps='Эпсилон';Zet='Дзета';Eta='Эта';The='Тета';Iot='Йота';Kap='Каппа';Lam='Лямбда';Mu='Мю';Nu='Ню';Xi='Кси';Omi='Омикрон';Pi='Пи';Rho='Ро';Sig='Сигма';Tau='Тау';Ups='Ипсилон';Phi='Фи';Chi='Хи';Psi='Пси';Ome='Омега'}
$proper = @{Sirius='Сириус';Alpheratz='Альферац';Mirach='Мирах';Almach='Альмах';Betelgeuse='Бетельгейзе';Rigel='Ригель';Vega='Вега';Altair='Альтаир';Deneb='Денеб';Arcturus='Арктур';Capella='Капелла';Aldebaran='Альдебаран';Antares='Антарес';Spica='Спика';Regulus='Регул';Procyon='Процион';Fomalhaut='Фомальгаут';Polaris='Полярная';Achernar='Ахернар';Canopus='Канопус';Acrux='Акрукс';Gacrux='Гакрукс';Hadar='Хадар';Mimosa='Мимоза';Castor='Кастор';Pollux='Поллукс';Bellatrix='Беллатрикс';Saiph='Сайф';Mintaka='Минтака';Alnilam='Альнилам';Alnitak='Альнитак';Dubhe='Дубхе';Merak='Мерак';Alioth='Алиот';Mizar='Мицар';Alkaid='Алькаид';Kochab='Кохаб';Pherkad='Феркад';Rasalhague='Рас Альхаге';Unukalhai='Унукальхай';Schedar='Шедар';'Rigil Kentaurus'='Ригиль Кентаврус';Elnath='Эль-Нат';Adhara='Адара';Kaffaljidhma='Каффалидма';Gienah='Гиена';'Cor Caroli'='Кор Кароли';Alhena='Альхена';Hamal='Хамаль';Gomeisa='Гомейза';Cebalrai='Цельбальрай';Alrescha='Альреша';Dschubba='Джубба';Peacock='Пеакок';'Prima Hyadum'='Прима Гиадум';'Secunda Hyadum'='Секунда Гиадум';Tianguan='Тянь-Гуань';Alya='Алия';Megrez='Мегрец'}
function Convert-Name([string]$name) {
  if ($proper.ContainsKey($name)) { return $proper[$name] }
  if ($name -match '^(?<n>\d+)\s+G\.\s*(?<c>[A-Z][a-zA-Z]{1,2})$' -and $genitive.ContainsKey($Matches.c)) {
    return "$($Matches.n) по каталогу Гулда $($genitive[$Matches.c])"
  }
  if ($name -match '^(?<n>\d+)?\s*(?<g>Alp|Bet|Gam|Del|Eps|Zet|Eta|The|Iot|Kap|Lam|Mu|Nu|Xi|Omi|Pi|Rho|Sig|Tau|Ups|Phi|Chi|Psi|Ome)\s*(?<v>\d*)\s*(?<c>[A-Z][a-zA-Z]{1,2})$' -and $genitive.ContainsKey($Matches.c)) {
    $prefix = if ($Matches.n) { "$($Matches.n) " } else { '' }; $suffix = if ($Matches.v) { " $($Matches.v)" } else { '' }
    $constellation = if ($genitive.ContainsKey($Matches.c)) { $genitive[$Matches.c] } else { $Matches.c }
    return "$prefix$($greek[$Matches.g])$suffix $constellation"
  }
  if ($name -match '^(?<n>\d+)\s+(?<c>[A-Z][a-zA-Z]{1,2})$') { return "$($Matches.n) $($genitive[$Matches.c])" }
  if ($name -match '^HIP\s*(?<n>\d+)$') { return "HIP $($Matches.n)" }
  # A transliteration label is preferable to silently retaining English prose for rare proper names.
  $value = $name -replace 'th','т' -replace 'sh','ш' -replace 'ch','ч' -replace 'ph','ф' -replace 'kh','х' -replace 'a','а' -replace 'b','б' -replace 'c','к' -replace 'd','д' -replace 'e','е' -replace 'f','ф' -replace 'g','г' -replace 'h','х' -replace 'i','и' -replace 'j','дж' -replace 'k','к' -replace 'l','л' -replace 'm','м' -replace 'n','н' -replace 'o','о' -replace 'p','п' -replace 'q','к' -replace 'r','р' -replace 's','с' -replace 't','т' -replace 'u','у' -replace 'v','в' -replace 'w','в' -replace 'x','кс' -replace 'y','й' -replace 'z','з'
  return $value.Substring(0, 1).ToUpperInvariant() + $value.Substring(1)
}
foreach ($row in $catalog.constellations) {
  foreach ($star in $row.stars) { $star | Add-Member -NotePropertyName name_ru -NotePropertyValue (Convert-Name $star.name) -Force }
  $bright = $row.stars | Sort-Object {[double]$_.magnitude} | Select-Object -First 1
  $row.explanation_ru = "$($row.name_ru) — одно из 88 официальных созвездий. Количество звёзд на учебной схеме: $($row.stars.Count). Самая яркая среди выбранных — $($bright.name_ru). Соединительные линии взяты из «Стеллариума» и не обозначают официальные границы или физические связи между звёздами."
}
$json = $catalog | ConvertTo-Json -Depth 20 -Compress
[IO.File]::WriteAllText($path, $json + "`n", [Text.UTF8Encoding]::new($false))
