<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Files;

class FilesController extends Controller
{
    const DEFAULT_LUA_DIRECTORY = 'app\\Lua\\';
    const STARTUP_FILE = 'startup.lua';

    /**
     * Récupérer un fichier dans un répertoire.
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse|\Illuminate\Http\Response
     */
    public function retrieveFile(Request $request)
    {
        $relativePath = $request->input('path', '');
        $fullPath = base_path(self::DEFAULT_LUA_DIRECTORY . $relativePath);
        $getRaw = $request->boolean('get_raw', false);

        $fileRecord = Files::where('path', $fullPath)->orderBy('version', 'desc')->first();
        
        if (!$fileRecord) {
            if (!is_file($fullPath)) {
                return response()->json(['error' => "Le fichier $relativePath n'existe pas"], 404);
            }

            $content = $this->getFileContent($fullPath);
            $fileRecord = $this->storeNewFile($fullPath, $content);
        } else {
            $content = $this->getFileContent($fullPath);
            if ($this->hasFileChanged($content, $fileRecord->hash)) {
                $fileRecord = $this->storeNewFile($fullPath, $content, $fileRecord->version);
            }
        }

        return $getRaw ? $this->sendRawContent($content) : $this->sendFileResponse($fileRecord);
    }

    /**
     * Récupérer la version d'un fichier.
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function retrieveFileVersion(Request $request)
    {
        $relativePath = $request->input('path', '');
        $fullPath = base_path(self::DEFAULT_LUA_DIRECTORY . $relativePath);

        $fileRecord = Files::where('path', $fullPath)->orderBy('version', 'desc')->first();

        if (!$fileRecord) {
            if (!is_file($fullPath)) {
                return response()->json(['error' => "Le fichier $relativePath n'existe pas"], 404);
            }

            $content = $this->getFileContent($fullPath);
            $fileRecord = $this->storeNewFile($fullPath, $content);
        } else {
            $content = $this->getFileContent($fullPath);
            if ($this->hasFileChanged($content, $fileRecord->hash)) {
                $fileRecord = $this->storeNewFile($fullPath, $content, $fileRecord->version);
            }
        }

        return response()->json(['version' => $fileRecord->version], 200);
    }

    /**
     * Récupérer la liste des fichiers dans un répertoire.
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function retrieveFilesList(Request $request)
    {
        $relativePath = $request->input('path', '');
        $fullPath = base_path(self::DEFAULT_LUA_DIRECTORY . $relativePath);

        if (!is_dir($fullPath)) {
            return response()->json(['error' => "Le répertoire $relativePath n'existe pas"], 404);
        }

        $files = array_values(array_diff(scandir($fullPath), ['.', '..']));

        return response()->json(['files' => $files], 200);
    }

    /**
     * Récupérer le fichier d'installation.
     * 
     * @param Request $request
     * @return \Illuminate\Http\Response
     */
    public function retrieveStartupFile(Request $request)
    {
        $fullPath = base_path(self::DEFAULT_LUA_DIRECTORY . self::STARTUP_FILE);

        if (!is_file($fullPath)) {
            return response()->json(['error' => "Le fichier de démarrage n'existe pas"], 404);
        }

        $content = $this->getFileContent($fullPath);

        return $this->sendRawContent($content);
    }

    /**
     * Récupérer et minifier le contenu d'un fichier.
     * 
     * @param string $filePath
     * @return string
     */
    protected function getFileContent(string $filePath): string
    {
        $content = file_get_contents($filePath);
        return $this->minifyLua($content);
    }

    /**
     * Vérifier si le fichier a changé.
     * 
     * @param string $content
     * @param string $existingHash
     * @return bool
     */
    protected function hasFileChanged(string $content, string $existingHash): bool
    {
        return hash('sha256', $content) !== $existingHash;
    }

    /**
     * Stocker un nouveau fichier dans la base de données.
     * 
     * @param string $filePath
     * @param string $content
     * @param string|null $currentVersion
     * @return Files
     */
    protected function storeNewFile(string $filePath, string $content, string $currentVersion = '1.0'): Files
    {
        $newVersion = $currentVersion ? $this->incrementVersion($currentVersion) : '1.0';
        $file = new Files();
        $file->content = $content;
        $file->hash = hash('sha256', $content);
        $file->path = $filePath;
        $file->version = $newVersion;
        $file->size = filesize($filePath);
        $file->save();

        return $file;
    }

    /**
     * Incrémenter la version d'un fichier.
     * 
     * @param string $currentVersion
     * @return string
     */
    protected function incrementVersion(string $currentVersion): string
    {
        [$major, $minor] = explode('.', $currentVersion);
        $minor++;
        return "$major.$minor";
    }

    /**
     * Retourner une réponse avec le fichier brut.
     * 
     * @param string $content
     * @return \Illuminate\Http\Response
     */
    protected function sendRawContent(string $content)
    {
        return response($content, 200)->header('Content-Type', 'text/plain');
    }

    /**
     * Retourner une réponse JSON avec les informations du fichier.
     * 
     * @param Files $file
     * @return \Illuminate\Http\JsonResponse
     */
    protected function sendFileResponse(Files $file)
    {
        return response()->json([
            'file' => [
                'version' => $file->version,
                'content' => $file->content
            ]
        ], 200);
    }

    /**
     * Minifier le code Lua.
     * 
     * @param string $content
     * @return string
     */
    protected function minifyLua(string $content): string
    {
        $content = preg_replace('/--.*$/m', '', $content);
        $content = preg_replace(['/[\s\t\n]+/m', '/\s*([\=\+\-\*\/\,\(\)\{\}])\s*/'], [' ', '$1'], $content);
        return preg_replace('/\s*([(){}=+\-*\/,])\s*/', '$1', $content);
    }
}
