-- Cette classe permet de charger la configuration initale et de préparer l'ordinateur

-- Opération de nettoyage des settings et des fichiers de l'ordinateur :
-- On va supprimer tous les fichiers et dossiers de l'ordinateur
local listeFichiers = fs.list("/")
for i = 1, #listeFichiers do
    fs.delete(listeFichiers[i])
end

-- On va commencer par demander le token à l'utilisateur