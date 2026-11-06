<?php

namespace Tests\Feature;

use Tests\TestCase;

class InventoryApiValidationTest extends TestCase
{
    public function test_sale_rejects_a_negative_quantity_before_calling_mysql(): void
    {
        $response = $this->postJson('/api/procedures/create-sale', [
            'customer_id' => 1,
            'product_id' => 1,
            'quantity' => -2,
        ]);

        $response
            ->assertUnprocessable()
            ->assertJsonPath('message', 'The given data was invalid.')
            ->assertJsonValidationErrors(['quantity']);
    }

    public function test_sale_total_requires_its_query_parameters(): void
    {
        $response = $this->getJson('/api/functions/calculate-sale-total');

        $response
            ->assertUnprocessable()
            ->assertJsonPath('message', 'The given data was invalid.')
            ->assertJsonValidationErrors(['product_id', 'quantity']);
    }
}
