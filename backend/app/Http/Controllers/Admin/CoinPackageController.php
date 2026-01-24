<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\CoinPackage;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class CoinPackageController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index(): JsonResponse
    {
        $packages = CoinPackage::orderBy('sort_order', 'asc')->get();

        return response()->json([
            'success' => true,
            'packages' => $packages,
        ]);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'label' => 'required|string|max:255',
            'price' => 'required|integer|min:0',
            'coins' => 'required|integer|min:0',
            'bonus' => 'nullable|integer|min:0',
            'is_active' => 'nullable|boolean',
            'sort_order' => 'nullable|integer',
        ]);

        $package = CoinPackage::create($validated);

        return response()->json([
            'success' => true,
            'message' => 'Coin package created successfully',
            'package' => $package,
        ]);
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, CoinPackage $coin_package): JsonResponse
    {
        $validated = $request->validate([
            'label' => 'sometimes|required|string|max:255',
            'price' => 'sometimes|required|integer|min:0',
            'coins' => 'sometimes|required|integer|min:0',
            'bonus' => 'nullable|integer|min:0',
            'is_active' => 'nullable|boolean',
            'sort_order' => 'nullable|integer',
        ]);

        $coin_package->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Coin package updated successfully',
            'package' => $coin_package,
        ]);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(CoinPackage $coin_package): JsonResponse
    {
        $coin_package->delete();

        return response()->json([
            'success' => true,
            'message' => 'Coin package deleted successfully',
        ]);
    }
}
