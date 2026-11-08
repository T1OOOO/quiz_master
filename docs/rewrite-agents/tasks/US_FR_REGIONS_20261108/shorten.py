"""One-off: shorten relations that exceeded validate.py limits (kept for the task record)."""
from pathlib import Path

p = Path(__file__).with_name("build.py")
s = p.read_text(encoding="utf-8")
R = {
"Bought from Russia in 1867 for $7.2 million at the urging of Secretary of State Seward, which enlarged the US by nearly a fifth; admitted on 3 January 1959. Its capital is Juneau, and Denali is the highest peak in North America.":
"Bought from Russia in 1867 for $7.2 million at Secretary of State Seward's urging, enlarging the US by nearly a fifth; admitted on 3 January 1959. Its capital is Juneau, and Denali is the highest peak in North America.",
"The largest state in area after Alaska; part of Mexico from 1821 to 1836, when it won independence as the Republic of Texas, it joined the Union as the 28th state in 1845. Austin is the capital and Houston the largest city.":
"Largest state in area after Alaska; part of Mexico from 1821 to 1836, when it won independence as the Republic of Texas, it joined the Union as the 28th state in 1845. Austin is the capital, Houston the largest city.",
"A peninsula between the Atlantic and the Gulf of Mexico with Tallahassee as capital; St. Augustine, founded in 1565 by the Spaniard Pedro Menéndez de Avilés, is the oldest European settlement in the continental United States.":
"Peninsula between the Atlantic and the Gulf of Mexico with Tallahassee as capital; St. Augustine, founded in 1565 by the Spaniard Pedro Menéndez de Avilés, is the oldest European settlement in the continental US.",
"The most arid state, with sandy alkali deserts of the Great Basin; silver mining boomed after the Comstock Lode of 1859, its capital is Carson City, and the legalisation of gambling in 1931 built the casinos of Las Vegas and Reno.":
"The most arid state, with the alkali deserts of the Great Basin; silver mining boomed after the Comstock Lode of 1859, its capital is Carson City, and gambling legalised in 1931 built the casinos of Las Vegas and Reno.",
"Claimed by La Salle in the name of Louis XIV; Spain returned Louisiana to France in 1800 and three years later the US bought it from Napoleon, the Louisiana Purchase. The state is divided into 64 parishes rather than counties; its capital is Baton Rouge.":
"Claimed by La Salle for Louis XIV; Spain returned it to France in 1800 and three years later the US bought it from Napoleon in the Louisiana Purchase. The state has 64 parishes instead of counties; its capital is Baton Rouge.",
"Pacific Northwest state and the only state named after a US president; its capital is Olympia, about half its people live in the Seattle–Tacoma–Bellevue area, and 14,410-foot Mount Rainier crowns its chain of volcanic peaks.":
"Pacific Northwest state, the only one named after a US president; its capital is Olympia, about half its people live in the Seattle–Tacoma–Bellevue area, and 14,410-foot Mount Rainier crowns its volcanic peaks.",
"The 47th state, admitted in 1912; its capital Santa Fe, founded by Spanish settlers in 1610, is the oldest continuously used seat of government in North America, and Los Alamos was the centre of the project that created the first atomic bomb in 1945.":
"The 47th state, admitted in 1912; its capital Santa Fe, founded by the Spanish in 1610, is the oldest continuously used seat of government in North America, and Los Alamos created the first atomic bomb in 1945.",
"47-й штат, принятый в 1912 году; столица Санта-Фе, основанная испанцами в 1610 году, — старейшая непрерывно действующая резиденция власти в Северной Америке, а Лос-Аламос был центром проекта, создавшего первую атомную бомбу в 1945 году.":
"47-й штат, принятый в 1912 году; столица Санта-Фе, основанная испанцами в 1610 году, — старейшая непрерывно действующая резиденция власти в Северной Америке, а в Лос-Аламосе в 1945 году создали первую атомную бомбу.",
"The only state split into two large land segments, joined since 1957 by the 5-mile Mackinac Bridge, and bordered by four of the five Great Lakes; its capital is Lansing, and Detroit became the world's automotive centre.":
"The only state split into two large land segments, joined since 1957 by the 5-mile Mackinac Bridge, and bordered by four of the five Great Lakes; its capital is Lansing, and Detroit became the world's car capital.",
"Congress first convened here in 1800; the city on the Potomac was laid out by Pierre Charles L'Enfant on land ceded by Maryland and Virginia (Virginia's part was later returned), and the District remains a territory, not a state.":
"Congress first convened here in 1800; the city on the Potomac was planned by Pierre Charles L'Enfant on land ceded by Maryland and Virginia (Virginia's part was later returned), and the District is not a state.",
"Hilly port city on the northern tip of a peninsula that boomed with the gold seekers of 1849, was devastated by the 1906 earthquake and the fires it set off, and is famous for its cable cars and the Golden Gate Bridge.":
"Hilly port city on the northern tip of a peninsula that boomed with the gold seekers of 1849, was devastated by the 1906 earthquake and its fires, and is famous for its cable cars and the Golden Gate Bridge.",
"Leading resort and Atlantic port in southern Florida, incorporated in 1896; some 500,000 Cubans settled here after 1959 and created Little Havana, while neighbouring Miami Beach keeps its Art Deco buildings of the mid-1930s.":
"Leading resort and Atlantic port in southern Florida, incorporated in 1896; some 500,000 Cubans settled here after 1959 and created Little Havana, and neighbouring Miami Beach keeps its mid-1930s Art Deco buildings.",
"Settled by English Puritans in 1630; the Boston Tea Party of 1773 was among the events marking the unrest before the American Revolution, the Freedom Trail links its historic sites, and Boston Common has been public open space since 1634.":
"Settled by English Puritans in 1630; the Boston Tea Party of 1773 marked the unrest before the American Revolution, the Freedom Trail links its historic sites, and Boston Common has been public open space since 1634.",
"Основан английскими пуританами в 1630 году; Бостонское чаепитие 1773 года — одно из событий нараставшего недовольства перед Американской революцией, Тропа свободы соединяет исторические места, а Бостон-Коммон открыт публике с 1634 года.":
"Основан английскими пуританами в 1630 году; Бостонское чаепитие 1773 года отметило рост недовольства перед Американской революцией, Тропа свободы соединяет исторические места, а Бостон-Коммон открыт публике с 1634 года.",
"Largest metropolis of the Pacific Northwest on Puget Sound, settled on 13 November 1851; Boeing, Microsoft and Amazon grew up around it, and Pike Place Market of 1907 is one of the oldest continuously operating public markets in the US.":
"Largest metropolis of the Pacific Northwest on Puget Sound, settled on 13 November 1851; Boeing, Microsoft and Amazon grew up around it, and Pike Place Market of 1907 is one of the oldest public markets in the US.",
"The fourth largest US city and a leading oil and petrochemical centre; since 1961 it has housed the Manned Spacecraft Center, renamed the Lyndon B. Johnson Space Center in 1973, the command post for US astronauts' flights.":
"The fourth largest US city and a leading oil and petrochemical centre; since 1961 it has housed the Manned Spacecraft Center, since 1973 the Lyndon B. Johnson Space Center, the command post for US astronauts' flights.",
"Naval base on southern Oahu about 10 km west of Honolulu; the surprise Japanese air attack of 7 December 1941 brought the US into the Second World War, and a white memorial stands over the sunken USS Arizona, lost with more than 1,100 men.":
"Naval base on southern Oahu about 10 km west of Honolulu; the surprise Japanese air attack of 7 December 1941 brought the US into the Second World War, and a white memorial stands over the sunken USS Arizona.",
"Военно-морская база на юге Оаху примерно в 10 км к западу от Гонолулу; внезапный японский авианалёт 7 декабря 1941 года ввёл США во Вторую мировую войну, а над затонувшим линкором «Аризона», унёсшим более 1100 человек, стоит белый мемориал.":
"Военно-морская база на юге Оаху примерно в 10 км к западу от Гонолулу; внезапный японский авианалёт 7 декабря 1941 года ввёл США во Вторую мировую войну, а над затонувшим линкором «Аризона» стоит белый мемориал.",
"Founded in 1701 by the French trader Antoine de la Mothe Cadillac on the Detroit River; it became the automobile capital of the world after Henry Ford introduced the assembly line in 1914, and Berry Gordy Jr. founded Motown here.":
"Founded in 1701 by the French trader Antoine de la Mothe Cadillac on the Detroit River; it became the car capital of the world after Henry Ford introduced the assembly line in 1914, and Berry Gordy Jr. founded Motown here.",
"held out for 13 days against the Mexican army before being killed;":
"held out for 13 days against the Mexican army and died;",
"NFL team from the small city of Green Bay, Wisconsin, organised in 1919 by Curly Lambeau and George Calhoun and a publicly owned nonprofit corporation since 1923; it won the first two Super Bowls under coach Vince Lombardi.":
"NFL team from the small city of Green Bay, Wisconsin, organised in 1919 by Curly Lambeau and George Calhoun, a publicly owned nonprofit since 1923; it won the first two Super Bowls under coach Vince Lombardi.",
"Peninsula protruding westward into the Atlantic, settled by Celts from Britain in the 5th and 6th centuries; the Breton language is still spoken, the region was incorporated into France by treaty in 1532, and its capital is Rennes.":
"Peninsula protruding westward into the Atlantic, settled by Celts from Britain in the 5th and 6th centuries; Breton is still spoken, the region joined France by treaty in 1532, and its capital is Rennes.",
"Stretch of the Loire from Sully-sur-Loire, east of Orléans, to Chalonnes, west of Angers, across the Centre-Val de Loire and Pays de la Loire regions; its châteaux such as Chambord and Chenonceau are a UNESCO site since 2000.":
"Stretch of the Loire from Sully-sur-Loire, east of Orléans, to Chalonnes, west of Angers, in the Centre-Val de Loire and Pays de la Loire regions; with châteaux such as Chambord and Chenonceau, a UNESCO site since 2000.",
"Largely mountainous Mediterranean island sold by Genoa to France in 1768; Napoleon Bonaparte was born in its capital Ajaccio on 15 August 1769, and since 1991 it has had the special status of a territorial collectivity.":
"Largely mountainous Mediterranean island sold by Genoa to France in 1768; Napoleon Bonaparte was born in its capital Ajaccio on 15 August 1769, and since 1991 it has had a special territorial status.",
"Historic region of the south-east that took its name from Gallia Transalpina, the first Roman provincia beyond the Alps, formed by the end of the 2nd century BCE; known for Arles, lavender fields and the popes who resided in Avignon in 1309–1377.":
"Historic south-eastern region named after Gallia Transalpina, the first Roman provincia beyond the Alps, formed by the end of the 2nd century BCE; known for Arles, lavender fields and the popes who lived in Avignon in 1309–1377.",
}
n = 0
for a, b in R.items():
    if a in s:
        s = s.replace(a, b)
        n += 1
    else:
        print("MISSING:", a[:60])
p.write_text(s, encoding="utf-8", newline="\n")
print("replaced", n)
