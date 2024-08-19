<?php

namespace App\Http\Controllers;

use App\Models\Todo;
use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Laravel\Jetstream\Jetstream;

class TodoController extends Controller
{
    public function index(Request $request)
    {
        $todos = Todo::all();
        return Jetstream::inertia()->render($request, 'Dev/Index', [
            'todos' => $todos
        ]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'task' => 'required|string|max:255',
        ]);

        Todo::create($request->all());

        return redirect()->back();
    }

    public function update(Request $request, Todo $todo)
    {
        $request->validate([
            'task' => 'required|string|max:255',
        ]);

        $todo->update($request->all());

        return redirect()->back();
    }

    public function destroy(Todo $todo)
    {
        $todo->delete();

        return redirect()->back();
    }
}

