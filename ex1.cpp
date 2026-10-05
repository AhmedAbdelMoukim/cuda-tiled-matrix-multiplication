#include <iostream>
#include <unordered_map>
#include <cstdint>
#include <iomanip>
#include <string>
#include <stdexcept>

using namespace std;
#define SET_BIT(set, index) ((set)[(index)/64] |= (1ULL << ((index) % 64)))
#define CLEAR_BIT(set, index) ((set)[(index)/64] &= ~(1ULL << ((index) % 64)))
#define GET_BIT(set, index) (((set)[(index)/64] >> ((index) % 64)) & 1ULL)
#define TRUNCATE(set, bits) ((set) & (((bits) == 64) ? 0xFFFFFFFFFFFFFFFFULL : ((1ULL << (bits)) - 1)))

int main(int argc,char* argv[]) {
    if(argc != 3) {
        cerr<<"Usage : "<<argv[0]<<" <longueur_historique 1..64> <type_predicteur 0|1>\n";
        return 1;
    }
    int longueurHistorique;
    int typePredicteur;
    try {
        longueurHistorique = stoi(argv[1]);
        typePredicteur = stoi(argv[2]);
    } catch(...) {
        cerr<<"Arguments invalides.\n";
        return 1;
    }

    if(longueurHistorique < 1 || longueurHistorique > 64) {
        cerr<<"La longueur de l historique doit etre entre 1 et 64.\n";
        return 1;
    }

    if(typePredicteur != 0 && typePredicteur != 1) {
        cerr<<"Le type du predicteur doit etre 0 ou 1.\n";
        return 1;
    }

    // table : historique -> etat du predicteur
    unordered_map<uint64_t,uint8_t> tablePrediction;

    // on garde l historique courant ici
    uint64_t bitsHistorique[1] = {0};

    // etat initial selon le type
    const uint8_t etatInitial = (typePredicteur == 0) ? 1 : 2;

    uint64_t nbPredictions = 0;
    uint64_t nbBonnesPredictions = 0;

    uint64_t idBranche;
    int resultatReel;

    while(cin>>idBranche>>resultatReel) {
        if(resultatReel != 0 && resultatReel != 1) {
            cerr<<"Resultat invalide dans l entree.\n";
            return 1;
        }

        uint64_t cleHistorique = TRUNCATE(bitsHistorique[0],longueurHistorique);

        // si cet historique n existe pas encore, on l initialise
        if(tablePrediction.find(cleHistorique) == tablePrediction.end()) {
            tablePrediction[cleHistorique] = etatInitial;
        }

        uint8_t& etatCourant = tablePrediction[cleHistorique];

        int prediction;
        if(typePredicteur == 0) {
            // bimodal 1 bit
            prediction = etatCourant;
        } else {
            // saturant 2 bits
            prediction = (etatCourant >= 2) ? 1 : 0;
        }

        if(prediction == resultatReel) {
            nbBonnesPredictions++;
        }
        nbPredictions++;

        // mise a jour de l etat du predicteur
        if(typePredicteur == 0) {
            etatCourant = static_cast<uint8_t>(resultatReel);
        } else {
            if(resultatReel == 1) {
                if(etatCourant < 3) {
                    etatCourant++;
                }
            } else {
                if(etatCourant > 0) {
                    etatCourant--;
                }
            }
        }

        // decalage de l historique vers la gauche
        for(int i = longueurHistorique - 1;i > 0;--i) {
            if(GET_BIT(bitsHistorique,i - 1)) {
                SET_BIT(bitsHistorique,i);
            } else {
                CLEAR_BIT(bitsHistorique,i);
            }
        }

        // le bit 0 recoit le nouveau resultat
        if(resultatReel == 1) {
            SET_BIT(bitsHistorique,0);
        } else {
            CLEAR_BIT(bitsHistorique,0);
        }

        // on garde seulement le nombre de bits voulu
        bitsHistorique[0] = TRUNCATE(bitsHistorique[0],longueurHistorique);
    }

    double tauxPrecision = 0.0;
    if(nbPredictions > 0) {
        tauxPrecision = (static_cast<double>(nbBonnesPredictions) * 100.0) / static_cast<double>(nbPredictions);
    }

    cout<<fixed<<setprecision(2)<<tauxPrecision<<"%\n";

    return 0;
}