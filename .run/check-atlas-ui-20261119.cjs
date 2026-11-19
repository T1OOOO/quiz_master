const {chromium}=require(require.resolve('playwright',{paths:[process.env.APPDATA+'/npm/node_modules/@playwright/test']}));
const assert=require('node:assert/strict');
const path=require('node:path');

const target=process.argv[2]||'http://127.0.0.1:8926/#/atlas/map-preview';
const artifactDir=process.env.USERPROFILE+'/.codex/visualizations/2026/10/26/01a17aa1-f379-7f20-8ed4-caef79d28e38';
const text=page=>page.locator('flt-semantics').evaluateAll(els=>els.map(e=>(e.getAttribute('aria-label')||e.innerText||'').trim()).filter(Boolean));
const button=(page,name)=>page.getByRole('button',{name}).first();

(async()=>{
  const browser=await chromium.launch({channel:'chrome',headless:true,args:['--enable-unsafe-swiftshader','--use-angle=swiftshader']});
  try {
    const page=await browser.newPage({viewport:{width:1200,height:820},locale:'ru-RU'});
    page.setDefaultTimeout(25000);
    page.on('pageerror',e=>console.log('pageerror',e.message));
    page.on('console',m=>{if(m.type()==='error')console.log('console',m.text().slice(0,240));});
    await page.goto(target,{waitUntil:'domcontentloaded'});
    await page.locator('flt-semantics-placeholder').waitFor({state:'attached'});
    await page.locator('flt-semantics-placeholder').evaluate(el=>el.click());
    await page.locator('.maplibregl-canvas').waitFor({timeout:120000});

    const c=await page.context().newCDPSession(page);
    const proto=await c.send('Runtime.evaluate',{expression:'maplibregl.Map.prototype'});
    const maps=await c.send('Runtime.queryObjects',{prototypeObjectId:proto.result.objectId});
    await c.send('Runtime.callFunctionOn',{objectId:maps.objects.objectId,functionDeclaration:'function(){window.atlasQA=Array.from(this).find(m=>m.getCanvas()?.isConnected);}'});
    await page.waitForFunction(()=>window.atlasQA?.getLayer('country-flags')&&window.atlasQA?.getLayer('water-labels'),null,{timeout:90000});
    const map=()=>page.evaluate(()=>window.atlasQA);
    const jump=(lon,lat,zoom)=>page.evaluate(([x,y,z])=>window.atlasQA.jumpTo({center:[x,y],zoom:z}),[lon,lat,zoom]);
    const layers=()=>page.evaluate(()=>['country-flags','country-labels','land','marine-highlight','lake-highlight','water-labels','rivers-detail'].filter(id=>window.atlasQA.getLayer(id)).map(id=>({id,paint:window.atlasQA.getPaintProperty(id,'fill-color')||window.atlasQA.getPaintProperty(id,'line-color')})));
    const snap=name=>page.screenshot({path:path.join(artifactDir,'atlas-ui-20261119-'+name+'.png')});

    await jump(10,51,3.2); await page.waitForTimeout(700);
    const visible=await page.evaluate(()=>({flags:window.atlasQA.queryRenderedFeatures({layers:['country-flags']}).length,labels:window.atlasQA.queryRenderedFeatures({layers:['country-labels']}).length}));
    assert.ok(visible.flags>0&&visible.labels>0,'visible country flags and labels');
    console.log('visible country markers',visible);

    const menu=button(page,/Параметры|Настройки|Menu|Settings/); await menu.click();
    await page.waitForTimeout(250);
    assert.ok((await text(page)).some(s=>/Население|Population|Площадь|Area/.test(s)),'menu opened');
    await page.keyboard.press('Escape'); await page.waitForTimeout(250);
    assert.ok(!(await text(page)).some(s=>/Население|Population/.test(s)),'escape closes menu');

    await menu.click();
    const thematic=page.getByText(/Население|Population/).first(); await thematic.click();
    await page.waitForTimeout(700);
    const thematicState=await page.evaluate(()=>({fill:window.atlasQA.getPaintProperty('thematic-countries','fill-color'),legend:document.body.innerText.includes('Население')||document.body.innerText.includes('Population')}));
    assert.ok(thematicState.fill&&thematicState.legend,'population thematic fill and legend');
    console.log('population thematic',JSON.stringify(thematicState)); await snap('population');

    await jump(10.2,51.1,5.2); await page.waitForTimeout(500);
    const germany=await page.evaluate(()=>window.atlasQA.queryRenderedFeatures({layers:['land','country-labels','country-flags']}).filter(f=>/DEU|Germany|Германи/.test(JSON.stringify(f.properties))).length);
    await jump(2.3,46.5,5.2); await page.waitForTimeout(500);
    const france=await page.evaluate(()=>window.atlasQA.queryRenderedFeatures({layers:['land','country-labels','country-flags']}).filter(f=>/FRA|France|Франц/.test(JSON.stringify(f.properties))).length);
    assert.ok(germany>0&&france>0,'Germany and France remain identifiable after map movement');
    const river=await page.evaluate(()=>window.atlasQA.queryRenderedFeatures({layers:['rivers','rivers-detail']}).filter(f=>/Rhein|Rhine|Рейн/i.test(JSON.stringify(f.properties))).length);
    console.log('Germany/France/Rhine',germany,france,river); await snap('europe-detail');

    const fillCheck=await layers(); assert.ok(fillCheck.some(x=>x.id==='marine-highlight')&&fillCheck.some(x=>x.id==='lake-highlight'),'water highlight layers');
    console.log('layers',JSON.stringify(fillCheck));
    console.log('ATLAS_UI_CHECK_OK');
  } finally { await browser.close(); }
})().catch(error=>{console.error(error);process.exitCode=1;});
