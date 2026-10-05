#include <iostream>
#include <vector>
#include <unordered_map>
#include <cstdint>
#include <iomanip>
#include <cstdlib>

using namespace std;
#define SET_BIT(set,index) ((set)[(index)/64] |= (1ULL << ((index) % 64)))
#define CLEAR_BIT(set,index) ((set)[(index)/64] &= ~(1ULL << ((index) % 64)))
#define GET_BIT(set,index) (((set)[(index)/64] >> ((index) % 64)) & 1ULL)
#define TRUNCATE(set,bits) ((set) & (((bits) == 64) ? 0xFFFFFFFFFFFFFFFFULL : ((1ULL << (bits)) - 1)))

int main(int argc,char* argv[]) {
    if(argc != 3) {
        cerr<<"Usage : "<<argv[0]<<" <longueur_historique (1-64)> <type_predicteur (0 ou 1)>\n";
        return 1;
    }
    int longueur = atoi(argv[1]);
    if(longueur < 1 || longueur > 64) {
        cerr<<"Erreur : la longueur doit etre entre 1 et 64.\n";
        return 1;
    }

    int type = atoi(argv[2]);
    if(type != 0 && type != 1) {
        cerr<<"Erreur : le type doit etre 0 ou 1.\n";
        return 1;
    }
    // une table pour chaque branche
    vector<unordered_map<uint64_t,uint8_t>> tables;
    // historique local de chaque branche
    vector<uint64_t> historiques;
    uint64_t total = 0;
    uint64_t bonnes = 0;

    uint64_t idBranche;
    int reel;

    uint8_t etatDepart;
    if(type == 0) {
        etatDepart = 1;
    } else {
        etatDepart = 2;
    }

    while(cin>>idBranche>>reel) {
        if(reel != 0 && reel != 1) {
            cerr<<"Erreur : la valeur lue doit etre 0 ou 1.\n";
            return 1;
        }
        // si l id est grand on agrandit les structures
        if(idBranche >= tables.size()) {
            tables.resize(idBranche + 1);
            historiques.resize(idBranche + 1,0);
        }

        uint64_t hist = TRUNCATE(historiques[idBranche],longueur);

        // si cet historique n existe pas encore pour cette branche
        if(tables[idBranche].find(hist) == tables[idBranche].end()) {
            tables[idBranche][hist] = etatDepart;
        }

        uint8_t& etat = tables[idBranche][hist];

        int prediction;
        if(type == 0) {
            prediction = etat;
        } else {
            if(etat >= 2) {
                prediction = 1;
            } else {
                prediction = 0;
            }
        }

        if(prediction == reel) {
            bonnes++;
        }
        total++;
        // mise a jour de l etat dans la table
        if(type == 0) {
            etat = (uint8_t)reel;
        } else {
            if(reel == 1) {
                if(etat < 3) {
                    etat++;
                }
            } else {
                if(etat > 0) {
                    etat--;
                }
            }
        }
        // mise a jour de l historique local de cette branche
        uint64_t bits[1] = {historiques[idBranche]};
        for(int i = longueur - 1;i > 0;--i) {
            if(GET_BIT(bits,i - 1)) {
                SET_BIT(bits,i);
            } else {
                CLEAR_BIT(bits,i);
            }
        }

        if(reel == 1) {
            SET_BIT(bits,0);
        } else {
            CLEAR_BIT(bits,0);
        }

        historiques[idBranche] = TRUNCATE(bits[0],longueur);
    }
    double precision = 0.0;
    if(total > 0) {
        precision = (double)bonnes * 100.0 / (double)total;
    }
    cout<<fixed<<setprecision(2)<<precision<<"%\n";

    return 0;
}