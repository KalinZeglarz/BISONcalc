%{
	#include <iostream>
	#include <stdio.h>
	#include <stdlib.h>
	#include <cstring>
	#include <map>
	#include <stack>
	#include <math.h>
	#include <algorithm>
	#include "struktury.h"

	int yylex();
	void yyerror(std::string message);

	std::map<std::string, int> zmienne;
	
	static const std::map<std::string, int> order = {{"",0},{"+",0},{"-",0},{"*",1},{"/",1},{"^",2}};
	inline int wykonaj(std::vector<Instrukcja>& instrukcje, int &i);
	inline int policz_wyrazenie(const std::vector<Rownania>& wyrazenie);
	inline void policz(int &liczba1, const std::string &operacja, int &liczba2);

	std::vector<Instrukcja> Instrukcje;
%}

%union {
    int iValue;
    std::string* vName;
	std::vector<Instrukcja>* Instrukcje;
    std::vector<Rownania>* Wyrazenia;
};


%start PROGRAM 
%type <Wyrazenia> EXP 
%type <iValue> CONDITION
%type <Instrukcje> ASSIGN
%type <Instrukcje> INSTRUCTION
%type <vName> VAR 

%token <iValue> NUMBER
%token <vName> CMP
%token <vName> OPERATOR


%token UNK PRINT VAR IF WHILE


%%
PROGRAM : PROGRAM INSTRUCTION ';' {
			for(int i = 0; i < $2->size(); i++){
                wykonaj(*$2, i);
			}
		}
		| PROGRAM INSTRUCTION { yyerror("Brak ';' na koncu wyrazenia"); }
		| /* nic */
		;

INSTRUCTION : PRINT EXP { $$ = new std::vector<Instrukcja>{Instrukcja(drukuj, *$2)}; }
			| ASSIGN { $$ = $1; }
			| IF CONDITION INSTRUCTION{
				$$ = $3;
				$$->insert($$->begin(), Instrukcja(jezeli, std::vector<Rownania>{Rownania($2)}));
			}
			| WHILE VAR ASSIGN INSTRUCTION {
				$$ = $4;
				$$->insert($$->begin(), $3->begin(), $3->end());
				Instrukcja temp;
				temp.typ = petla;
				temp.zmienna = *$2;
				$$->insert($$->begin(), temp);
			}
			;

ASSIGN : VAR '=' EXP { $$ = new std::vector<Instrukcja>{Instrukcja(alloc, *$3, *$1)};}

EXP : NUMBER {$$ = new std::vector<Rownania>{Rownania($1)};}
	| VAR { if(zmienne.find((*$1)) == zmienne.end()) yyerror(("Zmienna " + (*$1) + " undeclared").c_str() );
		$$ = new std::vector<Rownania>{Rownania(*$1)};
		}
	| EXP OPERATOR NUMBER {
		($$->back()).operacja = *$2;
		$$->emplace_back(Rownania($3));
	}
	| EXP OPERATOR VAR {
		($$->back()).operacja = *$2;
		$$->emplace_back(Rownania(*$3));
	}
	;

CONDITION : EXP { 
				int a = policz_wyrazenie(*$1);
				a != 0 ? $$ = 1 : $$ = 0;
			}
			| EXP CMP EXP {
				int a = policz_wyrazenie(*$1);
				int b = policz_wyrazenie(*$3);
				
				if((*$2) == ">") a > b ? $$ = 1: $$ = 0;
				else if((*$2) == "<") a < b ? $$ = 1 : $$ = 0;
				else if((*$2) == "==") a == b ? $$ = 1 : $$ = 0;
				else if((*$2) == ">=") a >= b ? $$ = 1 : $$ = 0;
				else if((*$2) == "<=") a <= b ? $$ = 1 : $$ = 0;
				else if((*$2) == "!=") a != b ? $$ = 1 : $$ = 0;
				else $$ = 0;
			}
			;

%%

int main(){
	yyparse();
	return 0;
}

void yyerror(std::string message){
	std::cerr << "Error: " << message << std::endl;
}

void policz(int& liczba1, const std::string& operacja, int& liczba2 ){
	if(operacja == "+") liczba1 += liczba2;
	else if(operacja == "-") liczba1 -= liczba2;
	else if(operacja == "*") liczba1 *= liczba2;
	else if(operacja == "/") liczba1 /= liczba2;
}

int	policz_wyrazenie(const std::vector<Rownania>& wyrazenie){
	int wynik = 0;
    int tmpCalc = 0;
	int tmpVar = 0;
	
	wyrazenie[0].zmienna == "" ? wynik = wyrazenie[0].wartosc : wynik = zmienne[wyrazenie[0].zmienna];
	if(wyrazenie.size() < 2) return wynik;

	std::stack<Rownania> zapamietane;

	for(int i = 0; i < wyrazenie.size() - 1; i++){
		wyrazenie[i+1].zmienna == "" ? tmpVar = wyrazenie[i+1].wartosc : tmpVar = zmienne[wyrazenie[i+1].zmienna];

        if( order.at(wyrazenie[i].operacja) >= order.at(wyrazenie[i+1].operacja) ) {
            zapamietane.empty() ? policz(wynik, wyrazenie[i].operacja, tmpVar) : policz(tmpCalc, wyrazenie[i].operacja, tmpVar);
        } else {
            tmpCalc = tmpVar; 
            zapamietane.emplace(wyrazenie[i]);
        }

        while(!zapamietane.empty()){
            if( order.at(zapamietane.top().operacja) >= order.at(wyrazenie[i + 1].operacja) ) {
                if( zapamietane.size() > 1 ) { 
                    zapamietane.top().zmienna == "" ? tmpVar = zapamietane.top().wartosc : tmpVar = zmienne[zapamietane.top().zmienna];      
					policz(tmpCalc, zapamietane.top().operacja, tmpVar);
                } else 
					policz(wynik, zapamietane.top().operacja, tmpCalc);

                zapamietane.pop();
                if(zapamietane.empty()) tmpCalc = 0;
            }
            else break;
        }
	}
	return wynik;
}

int wykonaj(std::vector<Instrukcja>& Instrukcje, int &i){
	Instrukcja &instr = Instrukcje[i];

	switch(instr.typ){
        case alloc : {
            zmienne[instr.zmienna] = policz_wyrazenie(instr.wyrazenie);
            std::cout << "Zmienna " << instr.zmienna << " ma wartosc " << zmienne[instr.zmienna] << std::endl;
            break;
        }
		case drukuj : {
            std::cout << policz_wyrazenie(instr.wyrazenie) << std::endl;
            break;
        }
		case jezeli : {
			if(instr.wyrazenie[0].wartosc == 0) i++;
			break;
		}
		case petla : {
			const std::string controlVar = instr.zmienna;
			int a = 2;
			int b = 1;
			i = i+2;
			while(zmienne[controlVar] != 0){
				wykonaj(Instrukcje, a); 
				wykonaj(Instrukcje, b);
			}
			break;
		}
    }
	return 0;
}