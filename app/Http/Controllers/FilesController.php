<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class FilesController extends Controller
{
    /**
     * Permet de récupérer un fichier dans un répertoire
     * Variable de la requête:
     * path : Chemin du répertoire (String : /path/to/file) le chemin est par défaut le répertoire Lua dans app
     * get_raw : Retourner le fichier brut (Boolean : true/false)
     * 
     * @param Request $request
     * @return json
    */
    public function retrieve_file(Request $request)
    {
        // Récupérer le chemin du répertoire
        $path = $request->input('path');
        $raw_path = $path;

        // Récupérer la variable get_raw pour savoir si on doit retourner le fichier brut
        $get_raw = $request->input('get_raw');

        // Vérifier si le chemin est vide
        if (empty($path)) {
            return response()->json([
                'error' => 'Le chemin du répertoire est vide'
            ], 400);
        }

        // On place le path dans le dossier app\Lua dans le répertoire de l'application
        $path = base_path('app\\Lua\\' . $path);

        // Vérifier si le répertoire existe
        if (!is_file($path)) {
            return response()->json([
                'error' => 'Le fichier ' . $raw_path . ' n\'existe pas'
            ], 404);
        }

        // Vérifier si on doit retourner le fichier brut
        if ($get_raw == 'true') {
            return response()->download($path);
        }
        
        // Retourner le contenu du fichier en JSON
        return response()->json([
            'file' => file_get_contents($path)
        ], 200);
    }

    /**
     * Permet de récupérer la liste des fichiers dans un répertoire
     * 
     * @param Request $request
     * @return json
    */
    public function retrieve_files_list(Request $request)
    {
        // Récupérer le chemin du répertoire
        $path = $request->input('path');
        $raw_path = $path;

        // Vérifier si le chemin est vide
        if (empty($path)) {
            return response()->json([
                'error' => 'Le chemin du répertoire est vide'
            ], 400);
        }

        // On place le path dans le dossier app\Lua dans le répertoire de l'application
        $path = base_path('app\\Lua\\' . $path);

        // Vérifier si le répertoire existe
        if (!is_dir($path)) {
            return response()->json([
                'error' => 'Le répertoire ' . $raw_path . ' n\'existe pas'
            ], 404);
        }else{
            $files = scandir($path);
            $files = array_diff($files, array('.', '..'));

            return response()->json([
                'files' => $files
            ], 200);
        }
    }

    /**
     * Permet de récupérer le fichier bootstrap.lua
     * 
     * @param Request $request
     * @return json
    */
    public function retrieve_bootstrap(Request $request)
    {
        // On place le path dans le dossier app\Lua dans le répertoire de l'application
        $path = base_path('app\\Lua\\bootstrap.lua');

        // Vérifier si le répertoire existe
        if (!is_file($path)) {
            return response()->json([
                'error' => 'Le fichier bootstrap.lua n\'existe pas'
            ], 404);
        }

        // Retourner le contenu du fichier en JSON
        return response()->download($path);
    }
}
