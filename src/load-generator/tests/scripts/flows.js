async function retailStoreBasicWF(
    page,
    userContext,
    events,
    test
) {
    await test.step('Go to Retail Store', async () => {
    const requestPromise = page.waitForRequest('http://retail-store-ecs-socrates-ui-1807770987.us-east-1.elb.amazonaws.com/');
    await page.goto('http://retail-store-ecs-socrates-ui-1807770987.us-east-1.elb.amazonaws.com/');
    const req = await requestPromise;
    });
    await test.step('Navigate Catalog', async () => {
    await page.locator('#menu-catalog').click();    
    await page.getByRole('link', { name: 'Clothing' }).click();
    await page.getByRole('link', { name: 'Accessories' }).click();
    });
    await test.step('Add Accessory to Cart', async () => {  
    await page.getByRole('link', { name: 'Product 1' }).nth(4).click();
    await page.getByRole('button', { name: '+" / "' }).click();
    await page.getByRole('button', { name: '" / " Add to Loadout' }).click();
    });
    await test.step('Add another item to the cart', async () => {  
    await page.locator('#menu-catalog').click();
    await page.locator('div:nth-child(3) > .bg-white > a').click();
    await page.getByRole('button', { name: '+" / "' }).click();
    await page.getByRole('button', { name: '" / " Add to Loadout' }).click();
    });
    await test.step('Checkout', async () => {  
    await page.getByRole('button', { name: '" / " Start Equipment' }).click();
    await page.getByRole('button', { name: 'Continue " / "' }).click();
    await page.getByText('Priority Mail Express 5 business days $').click();
    await page.getByRole('button', { name: 'Continue " / "' }).click();
    await page.getByRole('button', { name: 'Purchase " / "' }).click();
    });
}

module.exports = {
  retailStoreBasicWF
};