<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Files;

class FilesController extends Controller
{
    const DEFAULT_LUA_DIRECTORY = 'app\\Lua\\';
    const STARTUP_FILE = 'Base\\startup.lua';
    const BOOTSTRAP_FILE = 'Base\\bootstrap.lua';

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
        $version = $request->input('version', null);

        if ($version) {
            $fileRecord = Files::where('path', $fullPath)->where('version', $version)->first();
        } else {
            $fileRecord = Files::where('path', $fullPath)->orderBy('version', 'desc')->first();
        }
        
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
        $file_changed = false;

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
                $file_changed = true;
            }
        }

        return response()->json(['version' => $fileRecord->version, 'file_changed' => $file_changed], 200);
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

        // Retirer les fichiers cachés
        $files = array_filter($files, function ($file) {
            return strpos($file, '.') !== 0;
        });
        
        $files = array_values($files);

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
            return response()->json(['error' => "Le fichier d'installation n'existe pas"], 404);
        }

        // check if the file has changed
        $content = $this->getFileContent($fullPath);
        $fileRecord = Files::where('path', $fullPath)->orderBy('version', 'desc')->first();
        if (!$fileRecord) {
            $fileRecord = $this->storeNewFile($fullPath, $content);
        } else {
            if ($this->hasFileChanged($content, $fileRecord->hash)) {
                $fileRecord = $this->storeNewFile($fullPath, $content, $fileRecord->version);
            }
        }

        return $this->sendRawContent($content);
    }

    /**
     * Récupérer le fichier de démarrage.
     * 
     * @param Request $request
     * @return \Illuminate\Http\Response
     */
    public function retrieveBootstrapFile(Request $request)
    {
        $fullPath = base_path(self::DEFAULT_LUA_DIRECTORY . self::BOOTSTRAP_FILE);

        if (!is_file($fullPath)) {
            return response()->json(['error' => "Le fichier de démarrage n'existe pas"], 404);
        }

        // check if the file has changed
        $content = $this->getFileContent($fullPath);
        $fileRecord = Files::where('path', $fullPath)->orderBy('version', 'desc')->first();
        if (!$fileRecord) {
            $fileRecord = $this->storeNewFile($fullPath, $content);
        } else {
            if ($this->hasFileChanged($content, $fileRecord->hash)) {
                $fileRecord = $this->storeNewFile($fullPath, $content, $fileRecord->version);
            }
        }

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
        //$content = $this->minifyLua($content);

        return $content;
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
     * @param int|null $currentVersion
     * @return Files
     */
    protected function storeNewFile(string $filePath, string $content, ?int $currentVersion = null): Files
    {
        $newVersion = $currentVersion ? $currentVersion + 1 : 1;
        $file = new Files();
        $file->content = $content;
        $file->hash = hash('sha256', $content);
        $file->path = $filePath;
        $file->version = $newVersion;
        $file->size = strlen($content);
        $file->name = basename($filePath);
        $file->save();

        return $file;
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
     * Minify Lua code by removing unnecessary whitespace, comments, and newlines.
     * 
     * @param string $content
     * @return string
     */
    protected function minifyLua(string $content): string
    {
        // Remove block comments --[[]]
        $content = preg_replace('/--\[\[.*?\]\]/s', '', $content);

        // Remove single-line comments --
        $content = preg_replace('/--.*$/m', '', $content);

        // Replace multiple space characters with a single space without affecting newlines
        $content = preg_replace('/[ \t]+/', ' ', $content);

        // Replace multiple newline characters with a single newline
        $content = preg_replace('/\n+/', "\n", $content);

        // Remove empty lines
        $content = preg_replace('/^\s*[\r\n]/m', '', $content);

        // Remove space at the beginning of a line
        $content = preg_replace('/^\s+/m', '', $content);

        // Remove space at the end of a line
        $content = preg_replace('/\s+$/m', '', $content);

        return $content;
    }




}
