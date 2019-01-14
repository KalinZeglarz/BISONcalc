#ifndef STRUCTS_H
#define STRUCTS_H

#include <string>
#include <vector>
#include <iostream>

enum OPERATIONS { jezeli, drukuj, alloc, petla };


struct Rownania {
	std::string zmienna;
	int wartosc;
	std::string operacja = "";

	Rownania() {}
	Rownania(int& wartosc, std::string zmienna = "") : wartosc(wartosc), zmienna(zmienna) {}
	Rownania(std::string zmienna = "") : zmienna(zmienna) {}

};

struct Instrukcja {
	enum OPERATIONS typ;
	std::vector<Rownania> wyrazenie;
	std::string zmienna;

	Instrukcja() {}
	
    Instrukcja(OPERATIONS typ, std::vector<Rownania> wyrazenie, std::string zmienna = ""):
        typ(typ),
        wyrazenie(wyrazenie),
        zmienna(zmienna)
    {}
	void wyswietl() {
		const char* nazwaOperacji[] = { "jezeli", "drukuj", "alloc", "petla" };
		std::cout << "Instrukcja: typ(" << nazwaOperacji[this->typ] << "), zmienna(" << this->zmienna << "), wyrazenie(";

		for (int i = 0; i < wyrazenie.size(); i++) {
			if (wyrazenie[i].zmienna == "") std::cout << wyrazenie[i].wartosc << wyrazenie[i].operacja;
			else std::cout << wyrazenie[i].zmienna << wyrazenie[i].zmienna;
		}
		std::cout << ")" << std::endl;
	}
};

#endif