<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class ErrorController extends Controller
{
    // This method will be used to store the error in the database from api call
    public function store(Request $request)
    {
        // Validate the request
        $request->validate([
            'file_name' => 'required|integer',
            'version' => 'required|integer',
            'line_number' => 'required|integer',
            'error_message' => 'required|string',
        ]);
        
        // Retrieve the file from the database with the given name and version
        $file = File::where('name', $request->file_name)->where('version', $request->version)->first();

        // If the file does not exist, return an error
        if (!$file) {
            return response()->json(['error' => 'File not found'], 404);
        }

        // Create a new computer error
        $error = new ComputerError();
        $error->file_id = $file->id;
        $error->version = $request->version;
        $error->line_number = $request->line_number;
        $error->error_message = $request->error_message;
        $error->save();

        // Return the created error
        return response()->json($error, 201);
    }
}
