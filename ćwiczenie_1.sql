-- 2
create schema ksiegowosc;
-- 3
create table ksiegowosc.pracownicy (
    id_pracownika serial primary key,
    imie varchar(50),
    nazwisko varchar(50),
    adres text,
    telefon varchar(20)
);
comment on table ksiegowosc.pracownicy is 'dane pracowników firmy';

create table ksiegowosc.godziny (
    id_godziny serial primary key,
    data date,
    liczba_godzin numeric(5,2),
    id_pracownika int references ksiegowosc.pracownicy(id_pracownika)
);
comment on table ksiegowosc.godziny is 'dane dotyczące przepracowanych godzin';

create table ksiegowosc.pensja (
    id_pensji serial primary key,
    stanowisko varchar(50),
    kwota numeric(10,2)
);
comment on table ksiegowosc.pensja is 'dane dotyczące pensji pracowników';

create table ksiegowosc.premia (
    id_premii serial primary key,
    rodzaj varchar(50),
    kwota numeric(10,2)
);
comment on table ksiegowosc.premia is 'dane dotyczące premii pracowników';

create table ksiegowosc.wynagrodzenie (
    id_wynagrodzenia serial primary key,
    data date,
    id_pracownika int references ksiegowosc.pracownicy(id_pracownika),
    id_godziny int references ksiegowosc.godziny(id_godziny),
    id_pensji int references ksiegowosc.pensja(id_pensji),
    id_premii int references ksiegowosc.premia(id_premii)
);
comment on table ksiegowosc.wynagrodzenie is 'dane dotyczące łącznego wynagrodzenia pracowników';


-- 4
insert into ksiegowosc.pracownicy (imie, nazwisko, adres, telefon) values
('jan', 'kowalski', 'ul. kwiatowa 10, kraków', '123-456-789'),
('anna', 'nowak', 'ul. lipowa 5, kraków', '987-654-321'),
('piotr', 'wiśniewski', 'ul. słoneczna 12, kraków', '456-789-123'),
('ewa', 'zielińska', 'ul. wiosenna 3, kraków', '321-654-987'),
('marek', 'lewandowski', 'ul. letnia 7, kraków', '654-321-789'),
('katarzyna', 'dąbrowska', 'ul. jesienna 8, piekary', '789-123-456'),
('tomasz', 'woźniak', 'ul. zimowa 2, tyniec', '147-258-369'),
('agnieszka', 'kaczmarek', 'ul. różana 4, gaj', '963-852-741'),
('grzegorz', 'mazur', 'ul. polna 6, kraków', '852-741-963'),
('monika', 'wójcik', 'ul. zielona 9, kraków', '741-963-852');

insert into ksiegowosc.pensja (stanowisko, kwota) values
('kierownik', 5000.00),
('technik', 3500.00),
('magazynier', 2500.00),
('dyrektor', 7000.00),
('technik', 3000.00),
('konsultant', 3200.00),
('technik', 2800.00),
('kierownik', 4000.00),
('magazynier', 2200.00),
('magazynier', 2700.00);


insert into ksiegowosc.premia (rodzaj, kwota) values
('za wyniki', 500.00),
('świąteczna', 300.00),
('frekwencja', 200.00),
('roczna', 1000.00),
('motywacyjna', 700.00),
('uznaniowa', 400.00),
('roczna', 600.00),
('zadaniowa', 350.00),
('zadaniowa', 450.00),
('roczna', 800.00);

insert into ksiegowosc.godziny (data, liczba_godzin, id_pracownika) values
('2025-09-01', 160, 1),
('2025-09-01', 150, 2),
('2025-09-01', 170, 3),
('2025-09-01', 165, 4),
('2025-09-01', 155, 5),
('2025-09-01', 160, 6),
('2025-09-01', 140, 7),
('2025-09-01', 180, 8),
('2025-09-01', 160, 9),
('2025-09-01', 175, 10);

insert into ksiegowosc.wynagrodzenie (data, id_pracownika, id_godziny, id_pensji, id_premii) values
('2025-09-30', 1, 1, 1, 1),
('2025-09-30', 2, 2, 2, 2),
('2025-09-30', 3, 3, 3, 3),
('2025-09-30', 4, 4, 4, 4),
('2025-09-30', 5, 5, 5, 5),
('2025-09-30', 6, 6, 6, 6),
('2025-09-30', 7, 7, 7, 7),
('2025-09-30', 8, 8, 8, 8),
('2025-09-30', 9, 9, 9, 9),
('2025-09-30', 10, 10, 10, 10);

-- 5
set search_path to ksiegowosc;

-- a
select id_pracownika, nazwisko
from pracownicy;

-- b
select id_pracownika
from wynagrodzenie as w
join pensja as p on w.id_pensji = p.id_pensji
where w.id_pensji is null and p.kwota >= 2000;

-- c
select id_pracownika, p.kwota
from wynagrodzenie as w
join pensja as p on w.id_pensji = p.id_pensji
where p.kwota >= 2000;

-- d
select id_pracownika, imie
from pracownicy
where imie like 'j%';

-- e
select id_pracownika, imie, nazwisko
from pracownicy
where imie like '%a' and nazwisko like '%n%';

-- f
select p.imie, p.nazwisko, (liczba_godzin - 160) as "liczba nadgodzin"
from godziny as g
join pracownicy as p on g.id_pracownika = p.id_pracownika
where g.liczba_godzin > 160;

-- g
select p.imie, p.nazwisko, pn.kwota
from pracownicy as p
join wynagrodzenie as w on p.id_pracownika = w.id_pracownika
join pensja as pn on w.id_pensji = pn.id_pensji
where pn.kwota between 1500 and 3000;

-- h
select p.imie, p.nazwisko
from godziny as g
join pracownicy as p on g.id_pracownika = p.id_pracownika
join wynagrodzenie as w on g.id_pracownika = w.id_pracownika
join premia as pr on w.id_premii = pr.id_premii
where g.liczba_godzin > 160 and pr.kwota is null;

-- i
select id_pracownika, p.kwota
from wynagrodzenie as w
join pensja as p on w.id_pensji = p.id_pensji
order by p.kwota;

-- j
select id_pracownika, p.kwota
from wynagrodzenie as w
join pensja as p on w.id_pensji = p.id_pensji
join premia as pr on w.id_premii = pr.id_premii
order by p.kwota, pr.kwota desc;

-- k
select pn.stanowisko, count(distinct w.id_pracownika) as liczba_pracownikow
from pensja as pn
join wynagrodzenie as w on pn.id_pensji = w.id_pensji
group by pn.stanowisko;

-- l
select 
    p.stanowisko,
    avg(p.kwota) as srednia_placa,
    min(p.kwota) as minimalna_placa,
    max(p.kwota) as maksymalna_placa
from pensja as p
where p.stanowisko = 'kierownik'
group by p.stanowisko;

-- m
select sum(ps.kwota + coalesce(pr.kwota, 0)) as suma_wynagrodzen
from wynagrodzenie as w
join pensja as ps on w.id_pensji = ps.id_pensji
left join premia as pr on w.id_premii = pr.id_premii;

-- n
select ps.stanowisko, sum(ps.kwota + coalesce(pr.kwota, 0)) as suma_wynagrodzen
from wynagrodzenie as w
join pensja as ps on w.id_pensji = ps.id_pensji
left join premia as pr on w.id_premii = pr.id_premii
group by ps.stanowisko;

-- o
select ps.stanowisko, count(pr.id_premii) as liczba_premii
from wynagrodzenie as w
join pensja as ps on w.id_pensji = ps.id_pensji
left join premia as pr on w.id_premii = pr.id_premii
group by ps.stanowisko;


-- p
delete from wynagrodzenie
where id_pensji in (
    select id_pensji from pensja where kwota < 1200
);

delete from pracownicy
where id_pracownika not in (
    select id_pracownika from wynagrodzenie
);
