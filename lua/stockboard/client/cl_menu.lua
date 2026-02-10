-- lua/stockboard/client/cl_menu.lua

StockBoard.MenuFrame = nil
StockBoard.DHTML = nil

-- Local state variables
StockBoard.MarketData = {}
StockBoard.MyPortfolio = {}
StockBoard.MyStats = {}

local HTML_TEMPLATE = [==[
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<script src="https://cdn.tailwindcss.com"></script>
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
<script>
tailwind.config = {
    theme: {
        extend: {
            colors: {
                'sb': {
                    'bg':       '#{{BgPage}}',
                    'card':     '#{{BgCard}}',
                    'card2':    '#{{BgCardHover}}',
                    'border':   '#{{Border}}',
                    'border2':  '#{{BorderHover}}',
                    'accent':   '#{{Accent}}',
                    'accentdk': '#{{AccentHover}}',
                    'accentlt': '#{{AccentLight}}',
                    'title':    '#{{TextTitle}}',
                    'text':     '#{{TextPrimary}}',
                    'text2':    '#{{TextSecondary}}',
                    'success':  '#{{Success}}',
                    'danger':   '#{{Danger}}',
                    'info':     '#{{Info}}',
                }
            }
        }
    }
}
</script>
<style>
    @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800;900&display=swap');
    *, *::before, *::after { margin: 0; padding: 0; box-sizing: border-box; outline: none !important; }
    *:focus, *:focus-visible { outline: none !important; }
    body { background: transparent; font-family: 'Inter', sans-serif; color: #{{TextPrimary}}; overflow: hidden; }
    ::-webkit-scrollbar { width: 4px; }
    ::-webkit-scrollbar-track { background: transparent; }
    ::-webkit-scrollbar-thumb { background: #{{Border}}; border-radius: 4px; }
    ::-webkit-scrollbar-thumb:hover { background: #{{BorderHover}}; }
    @keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
    @keyframes slideUp { from { opacity: 0; transform: translateY(30px) scale(0.97); } to { opacity: 1; transform: translateY(0) scale(1); } }
    
    .tab-btn-active { @apply hidden; }
    .tab-btn-inactive { @apply hidden; }
    
    .stock-card { @apply bg-sb-card border border-sb-border rounded-xl p-4 hover:border-sb-accent hover:bg-sb-card2 transition-all duration-200 relative overflow-hidden; }
    .trend-up { @apply text-sb-success; }
    .trend-down { @apply text-sb-danger; }
    @keyframes toastIn { from { transform: translateX(100%); opacity: 0; } to { transform: translateX(0); opacity: 1; } }
    @keyframes toastOut { from { transform: translateX(0); opacity: 1; } to { transform: translateX(100%); opacity: 0; } }
    .toast-in { animation: toastIn 0.25s ease forwards; }
    .toast-out { animation: toastOut 0.3s ease forwards; }
</style>
</head>
<body>

<div id="app" class="h-screen flex flex-col animate-[fadeIn_0.2s_ease]" style="background: rgba(0,0,0,0.8);">
  <div class="max-w-7xl w-full mx-auto flex flex-col flex-1 overflow-hidden">
    
    <!-- HEADER -->
    <div class="flex items-center justify-between px-8 py-5 border-b border-white/5">
        <div class="flex items-center gap-4">
            <div class="w-12 h-12 rounded-xl bg-gradient-to-br from-sb-accent to-sb-accentdk flex items-center justify-center shadow-lg shadow-sb-accent/20">
                <i class="fa-solid fa-chart-simple text-sb-bg text-2xl"></i>
            </div>
            <div>
                <h1 class="text-2xl font-black text-sb-title tracking-tight leading-none">{{Title}}</h1>
                <p class="text-xs text-sb-text2 font-bold tracking-[0.2em] uppercase mt-1">{{Subtitle}}</p>
            </div>
        </div>

        <div class="flex items-center gap-1">
            <button onclick="switchTab('market')" id="tab-market" class="rounded-full bg-sb-accent text-sb-bg border border-sb-accent px-5 py-2 text-sm font-bold flex items-center gap-2 transition-all duration-150 hover:opacity-90">
                <i class="fa-solid fa-shop text-xs"></i> {{TabMarket}}
            </button>
            <button onclick="switchTab('portfolio')" id="tab-portfolio" class="rounded-full bg-sb-card text-sb-text2 border border-sb-border px-5 py-2 text-sm font-medium flex items-center gap-2 transition-all duration-150 hover:bg-sb-card2 hover:text-sb-text hover:border-sb-border2">
                <i class="fa-solid fa-wallet text-xs"></i> {{TabPortfolio}}
            </button>
            <button onclick="switchTab('charts')" id="tab-charts" class="rounded-full bg-sb-card text-sb-text2 border border-sb-border px-5 py-2 text-sm font-medium flex items-center gap-2 transition-all duration-150 hover:bg-sb-card2 hover:text-sb-text hover:border-sb-border2">
                <i class="fa-solid fa-chart-line text-xs"></i> {{TabCharts}}
            </button>
            <button onclick="switchTab('stats')" id="tab-stats" class="rounded-full bg-sb-card text-sb-text2 border border-sb-border px-5 py-2 text-sm font-medium flex items-center gap-2 transition-all duration-150 hover:bg-sb-card2 hover:text-sb-text hover:border-sb-border2">
                <i class="fa-solid fa-trophy text-xs"></i> {{TabStats}}
            </button>
        </div>

        <button onclick="sb.close()" class="w-10 h-10 rounded-lg flex items-center justify-center bg-black text-white hover:bg-white hover:text-black transition">
            <i class="fa-solid fa-xmark text-xl"></i>
        </button>
    </div>

    <!-- CONTENT -->
    <div class="flex-1 overflow-hidden relative">
        
        <!-- MARKET TAB -->
        <div id="page-market" class="h-full overflow-y-auto px-8 py-6">
            <!-- Event Banner -->
            <div id="market-event" class="hidden mb-6 rounded-xl p-4 border border-l-4 flex items-center gap-4 animate-[slideUp_0.3s_ease]">
                <div id="event-icon" class="text-2xl w-10 text-center"></div>
                <div>
                    <h3 class="font-bold text-lg" id="event-text"></h3>
                    <p class="text-xs opacity-75">Active Market Event</p>
                </div>
            </div>
            
            <div class="grid grid-cols-4 gap-4" id="market-grid">
                <!-- Cards injected via JS -->
            </div>
        </div>

        <!-- PORTFOLIO TAB -->
        <div id="page-portfolio" class="h-full overflow-y-auto px-8 py-6 hidden">
            <div class="grid grid-cols-3 gap-6 mb-8">
                <div class="bg-sb-card border border-sb-border rounded-xl p-6 relative overflow-hidden group">
                    <div class="absolute right-0 top-0 p-4 transition transform group-hover:scale-110">
                        <i class="fa-solid fa-vault text-4xl text-sb-accent"></i>
                    </div>
                    <p class="text-sb-text2 text-xs font-bold uppercase tracking-wider mb-1">{{LblTotalVal}}</p>
                    <div class="text-4xl font-black text-white" id="port-total">0</div>
                </div>
                <!-- Add more stats here if needed -->
            </div>

            <div class="bg-sb-card border border-sb-border rounded-xl overflow-hidden">
                <table class="w-full text-left border-collapse">
                    <thead class="bg-sb-card2 text-xs uppercase text-sb-text2 font-bold">
                        <tr>
                            <th class="p-4 pl-6">Company</th>
                            <th class="p-4 text-center">{{LblShares}}</th>
                            <th class="p-4 text-right">{{LblAvgPrice}}</th>
                            <th class="p-4 text-right">{{LblCurrent}}</th>
                            <th class="p-4 text-right">{{LblReturn}}</th>
                            <th class="p-4 text-right">Action</th>
                        </tr>
                    </thead>
                    <tbody id="portfolio-list" class="divide-y divide-sb-border">
                        <!-- Rows injected via JS -->
                    </tbody>
                </table>
                <div id="portfolio-empty" class="hidden p-12 text-center text-sb-text2">
                    <i class="fa-solid fa-folder-open text-4xl mb-3 opacity-50"></i>
                    <p>{{EmptyPort}}</p>
                </div>
            </div>
        </div>

        <!-- CHARTS TAB -->
        <div id="page-charts" class="flex-1 min-h-0 overflow-hidden px-8 py-6 hidden flex gap-6">
            <!-- Left Sidebar -->
            <div class="w-1/4 h-full flex flex-col gap-3 overflow-y-auto pr-2" id="chart-list">
                <!-- List Items injected -->
            </div>
            
            <!-- Right Content -->
            <div class="flex-1 bg-sb-card border border-sb-border rounded-xl p-6 flex flex-col h-full">
                <div class="flex items-center justify-between mb-6">
                    <div class="flex items-center gap-3">
                        <div id="chart-icon" class="w-10 h-10 rounded-lg bg-sb-card2 flex items-center justify-center text-xl"></div>
                        <div>
                            <h2 id="chart-title" class="text-2xl font-bold"></h2>
                            <p id="chart-sector" class="text-xs text-sb-text2 uppercase tracking-wider"></p>
                        </div>
                    </div>
                    <div class="text-right">
                        <div id="chart-price" class="text-3xl font-black"></div>
                        <div id="chart-change" class="text-sm font-bold"></div>
                    </div>
                </div>
                <div class="flex-1 w-full relative">
                    <canvas id="main-chart" class="w-full h-full"></canvas>
                </div>
            </div>
        </div>

        <!-- STATS TAB -->
        <div id="page-stats" class="h-full overflow-y-auto px-8 py-6 hidden">
            <!-- Player Stats Grid -->
            <div class="grid grid-cols-4 gap-4 mb-8">
                <div class="bg-sb-card border border-sb-border rounded-xl p-5">
                    <p class="text-xs text-sb-text2 font-bold uppercase mb-1">{{LblInvested}}</p>
                    <div class="text-2xl font-bold text-white" id="stat-invested">0</div>
                </div>
                <div class="bg-sb-card border border-sb-border rounded-xl p-5">
                    <p class="text-xs text-sb-text2 font-bold uppercase mb-1">{{LblProfit}}</p>
                    <div class="text-2xl font-bold" id="stat-profit">0</div>
                </div>
                <div class="bg-sb-card border border-sb-border rounded-xl p-5">
                    <p class="text-xs text-sb-text2 font-bold uppercase mb-1">{{LblTrades}}</p>
                    <div class="text-2xl font-bold text-white" id="stat-trades">0</div>
                </div>
                <div class="bg-sb-card border border-sb-border rounded-xl p-5">
                    <p class="text-xs text-sb-text2 font-bold uppercase mb-1">{{LblBest}}</p>
                    <div class="text-2xl font-bold text-sb-success" id="stat-best">0</div>
                </div>
            </div>

            <!-- Rank Progress -->
            <div class="bg-sb-card border border-sb-border rounded-xl p-6 mb-8 flex items-center gap-6">
                <div class="w-16 h-16 rounded-full bg-sb-accent/10 flex items-center justify-center border-2 border-sb-accent text-sb-accent text-2xl">
                    <i id="rank-icon" class="fa-solid fa-user"></i>
                </div>
                <div class="flex-1">
                    <div class="flex justify-between items-end mb-2">
                        <div>
                            <p class="text-xs text-sb-text2 font-bold uppercase">{{LblRank}}</p>
                            <h2 class="text-xl font-black text-sb-accent" id="rank-name">Intern</h2>
                        </div>
                        <div class="text-right">
                            <p class="text-xs text-sb-text2 font-bold" id="rank-next-label">Next: Trader</p>
                            <p class="text-sm font-bold text-white" id="rank-progress-text">0 / 5,000</p>
                        </div>
                    </div>
                    <div class="h-3 bg-sb-card2 rounded-full overflow-hidden">
                        <div id="rank-bar" class="h-full bg-sb-accent transition-all duration-500" style="width: 0%"></div>
                    </div>
                </div>
            </div>

            <!-- Leaderboard -->
            <div class="flex items-center justify-between mb-4">
                <h3 class="text-lg font-bold text-white flex items-center gap-2">
                    <i class="fa-solid fa-ranking-star text-sb-accent"></i> Top Investors
                </h3>
                <div class="flex gap-2">
                    <button id="lb-btn-totalProfit" onclick="reqLb('totalProfit')" class="text-xs font-bold px-3 py-1 rounded bg-sb-accent text-sb-bg border border-sb-accent">Profit</button>
                    <button id="lb-btn-trades" onclick="reqLb('trades')" class="text-xs font-bold px-3 py-1 rounded bg-sb-card border border-sb-border hover:border-sb-accent">Trades</button>
                </div>
            </div>
            <div class="bg-sb-card border border-sb-border rounded-xl overflow-hidden" id="lb-container">
                <!-- LB items -->
            </div>
        </div>

    </div>
  </div>
</div>



<!-- MODAL (Buy/Sell) -->
<div id="modal" class="hidden fixed top-0 left-0 w-screen h-screen z-50 flex items-center justify-center bg-black/80 animate-[fadeIn_0.15s_ease]" onclick="closeModal(event)">
    <div id="modal-card" class="bg-sb-card border border-sb-border w-[400px] rounded-2xl overflow-hidden animate-[slideUp_0.2s_ease]" onclick="event.stopPropagation()">
        <!-- Header -->
        <div class="bg-sb-card2 p-5 border-b border-sb-border flex justify-between items-center">
            <h3 class="font-bold text-lg" id="modal-title">Trade</h3>
            <button onclick="closeModal()" class="w-8 h-8 rounded-full bg-sb-bg border border-sb-border flex items-center justify-center text-sb-text2 hover:text-white hover:border-sb-accent transition"><i class="fa-solid fa-times"></i></button>
        </div>
        <!-- Body -->
        <div class="p-6">
            <div class="flex items-center gap-4 mb-6">
                <div id="modal-icon" class="w-12 h-12 rounded-lg bg-sb-card2 flex items-center justify-center text-2xl"></div>
                <div>
                    <div id="modal-stock-name" class="font-bold text-xl"></div>
                    <div id="modal-price" class="text-sb-text2 font-mono"></div>
                </div>
            </div>

            <div class="mb-6">
                <label class="block text-xs font-bold text-sb-text2 uppercase mb-2">Quantity</label>
                <div class="grid grid-cols-5 gap-2">
                    <button onclick="adjQty(-10)" class="h-10 rounded-lg bg-sb-card2 border border-sb-border font-bold text-sm hover:bg-white/5 hover:border-sb-accent transition">-10</button>
                    <button onclick="adjQty(-1)" class="h-10 rounded-lg bg-sb-card2 border border-sb-border font-bold text-sm hover:bg-white/5 hover:border-sb-accent transition">-1</button>
                    <input type="number" id="modal-qty" class="bg-sb-bg border border-sb-border rounded-lg text-center font-bold focus:border-sb-accent transition" value="1" oninput="calcTotal()">
                    <button onclick="adjQty(1)" class="h-10 rounded-lg bg-sb-card2 border border-sb-border font-bold text-sm hover:bg-white/5 hover:border-sb-accent transition">+1</button>
                    <button onclick="adjQty(10)" class="h-10 rounded-lg bg-sb-card2 border border-sb-border font-bold text-sm hover:bg-white/5 hover:border-sb-accent transition">+10</button>
                </div>
            </div>

            <div class="flex justify-between items-center mb-6 py-3 border-t border-b border-sb-border border-dashed">
                <span class="text-sm font-bold text-sb-text2">Total (incl. fees)</span>
                <span id="modal-total" class="text-xl font-black text-white">$0</span>
            </div>

            <button id="modal-btn" onclick="confirmTrade()" class="w-full py-3 rounded-lg font-bold text-sb-bg bg-sb-accent hover:bg-sb-accentdk transition">
                CONFIRM
            </button>
        </div>
    </div>
</div>

<!-- Toast notifications -->
<div id="toast-container" class="fixed top-4 right-4 flex flex-col gap-2 z-[9999] max-w-sm"></div>

<script>
    // --- CONFIG & STATE ---
    const CFG = {{ConfigJSON}};
    const STOCKS = {{StocksJSON}};
    const RANKS = {{RanksJSON}};
    const CURRENCY = "{{CurrencySymbol}}";
    
    let marketData = {};
    let portfolio = {};
    let activeEvent = null;
    let selectedStockId = null; // for modal
    let selectedChartId = STOCKS[0].id;
    let tradeType = 'buy'; // or 'sell'
    let currentQty = 1;
    let playerStats = {};
    var playerWallet = 0;

    // --- TABS CONFIG ---
    const TAB_ACTIVE_CLS = ['bg-sb-accent', 'text-sb-bg', 'border-sb-accent', 'font-bold', 'hover:opacity-90'];
    const TAB_INACTIVE_CLS = ['bg-sb-card', 'text-sb-text2', 'border-sb-border', 'font-medium', 'hover:bg-sb-card2', 'hover:text-sb-text', 'hover:border-sb-border2'];

    // --- NOTIFICATIONS ---
    const TOAST_ICONS = {
        error:   'fa-circle-exclamation',
        success: 'fa-circle-check',
        warning: 'fa-triangle-exclamation',
        info:    'fa-circle-info',
    };
    const TOAST_COLORS = {
        error:   { bg: 'bg-red-500/15', border: 'border-red-500/30', text: 'text-red-400', icon: 'text-red-400' },
        success: { bg: 'bg-emerald-500/15', border: 'border-emerald-500/30', text: 'text-emerald-400', icon: 'text-emerald-400' },
        warning: { bg: 'bg-amber-500/15', border: 'border-amber-500/30', text: 'text-amber-400', icon: 'text-amber-400' },
        info:    { bg: 'bg-blue-500/15', border: 'border-blue-500/30', text: 'text-blue-400', icon: 'text-blue-400' },
    };

    function showNotification(msg, type) {
        type = type || 'info';
        const c = TOAST_COLORS[type] || TOAST_COLORS.info;
        const icon = TOAST_ICONS[type] || TOAST_ICONS.info;
        const container = document.getElementById('toast-container');

        const el = document.createElement('div');
        el.className = `flex items-center gap-3 px-4 py-3 rounded-lg border ${c.bg} ${c.border} backdrop-blur-sm toast-in`;
        el.innerHTML = `<i class="fa-solid ${icon} ${c.icon} text-base shrink-0"></i><span class="${c.text} text-sm font-medium">${msg}</span>`;

        container.appendChild(el);

        // Keep max 5
        while (container.children.length > 5) container.removeChild(container.firstChild);

        setTimeout(() => {
            el.classList.remove('toast-in');
            el.classList.add('toast-out');
            el.addEventListener('animationend', () => el.remove());
        }, 4500);
    }

    function bridgeNotify(json) {
        let d = JSON.parse(json);
        showNotification(d.msg, d.type);
    }

    // --- UTILS ---
    function formatMoney(val) { return CURRENCY + new Intl.NumberFormat().format(val); }
    function esc(s) { return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;'); }
    
    function getStock(id) { return STOCKS.find(s => s.id === id); }
    
    // --- TABS ---
    function switchTab(id) {
        ['market', 'portfolio', 'charts', 'stats'].forEach(t => {
            document.getElementById('page-' + t).classList.toggle('hidden', t !== id);
            let btn = document.getElementById('tab-' + t);
            if (t === id) {
                TAB_INACTIVE_CLS.forEach(c => btn.classList.remove(c));
                TAB_ACTIVE_CLS.forEach(c => btn.classList.add(c));
            } else {
                TAB_ACTIVE_CLS.forEach(c => btn.classList.remove(c));
                TAB_INACTIVE_CLS.forEach(c => btn.classList.add(c));
            }
        });
        if (id === 'charts') renderCharts();
        if (id === 'stats') sb.reqLb('totalProfit');
        if (id === 'market') setTimeout(renderMarket, 50); // slight delay to ensure layout is ready
    }

    // --- RENDER MARKET ---
    function renderMarket() {
        const grid = document.getElementById('market-grid');
        grid.innerHTML = STOCKS.map(s => {
            let data = marketData[s.id] || { current: s.basePrice, lastChange: 0, history: [] };
            let changeClass = data.lastChange >= 0 ? 'text-sb-success' : 'text-sb-danger';
            let changeIcon = data.lastChange >= 0 ? 'fa-caret-up' : 'fa-caret-down';
            
            return `
            <div class="stock-card group" onclick="openChart('${s.id}')" style="background: linear-gradient(135deg, #${s.color}11 0%, #${s.color}06 100%)">
                <div class="flex items-start justify-between mb-3">
                    <div class="flex items-center gap-3">
                        <div class="w-10 h-10 rounded-lg bg-white/5 flex items-center justify-center text-lg" style="color:#${s.color}">
                            <i class="fa-solid ${s.icon}"></i>
                        </div>
                        <div>
                            <div class="font-bold leading-tight">${s.name}</div>
                            <div class="text-[10px] text-sb-text2 uppercase tracking-wider">${s.id}</div>
                        </div>
                    </div>
                    <div class="text-right">
                        <div class="font-black text-lg">${formatMoney(data.current)}</div>
                        <div class="text-xs font-bold ${changeClass}">
                            <i class="fa-solid ${changeIcon}"></i> ${Math.abs(data.lastChange)}%
                        </div>
                    </div>
                </div>
                
                <!-- Sparkline Canvas -->
                <div class="h-12 w-full mb-3">
                    <canvas id="spark-${s.id}" class="w-full h-full"></canvas>
                </div>

                <div class="flex gap-2 opacity-50 group-hover:opacity-100 transition-opacity" onclick="event.stopPropagation()">
                    ${(portfolio[s.id] && portfolio[s.id].shares > 0)
                        ? `<button onclick="openModal('sell', '${s.id}')" class="flex-1 bg-sb-danger/10 text-sb-danger border border-sb-danger/20 hover:bg-sb-danger hover:text-white rounded py-2 text-xs font-bold transition">SELL</button>`
                        : `<button disabled class="flex-1 bg-white/5 text-sb-text2/40 border border-sb-border/30 rounded py-2 text-xs font-bold cursor-not-allowed">SELL</button>`
                    }
                    <button onclick="openModal('buy', '${s.id}')" class="flex-1 bg-sb-success/10 text-sb-success border border-sb-success/20 hover:bg-sb-success hover:text-white rounded py-2 text-xs font-bold transition">BUY</button>
                </div>
            </div>
            `;
        }).join('');

        // Draw sparklines
        STOCKS.forEach(s => {
            let data = marketData[s.id];
            if (data && data.history) drawSparkline('spark-' + s.id, data.history, '#' + s.color);
        });
    }

    function drawSparkline(id, data, color) {
        const cvs = document.getElementById(id);
        if (!cvs) return;
        const ctx = cvs.getContext('2d');
        // Fix DPI blur
        const rect = cvs.getBoundingClientRect();
        cvs.width = rect.width; cvs.height = rect.height;
        
        if (!data || data.length < 2) return;
        
        let min = Math.min(...data), max = Math.max(...data);
        let range = max - min || 1;
        let pad = cvs.height * 0.1;
        
        ctx.strokeStyle = color;
        ctx.lineWidth = 2;
        ctx.beginPath();
        
        data.forEach((val, i) => {
            let x = (i / (data.length - 1)) * cvs.width;
            let y = cvs.height - ((val - min) / range * (cvs.height - 2*pad) + pad);
            if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
        });
        ctx.stroke();
    }

    // --- RENDER PORTFOLIO ---
    function renderPortfolio() {
        const tbody = document.getElementById('portfolio-list');
        const empty = document.getElementById('portfolio-empty');
        let totalVal = 0;
        let hasItems = false;
        
        let html = STOCKS.map(s => {
            let p = portfolio[s.id];
            if (!p || p.shares <= 0) return '';
            hasItems = true;
            
            let data = marketData[s.id];
            let currentPrice = data ? data.current : s.basePrice;
            let val = p.shares * currentPrice;
            totalVal += val;
            
            let profit = val - (p.shares * p.avgPrice);
            let profitP = ((currentPrice - p.avgPrice) / p.avgPrice) * 100;
            let profitClass = profit >= 0 ? 'text-sb-success' : 'text-sb-danger';
            
            return `
            <tr class="hover:bg-sb-card2/50 transition">
                <td class="p-4 pl-6">
                    <div class="flex items-center gap-3">
                        <div class="w-8 h-8 rounded bg-white/5 flex items-center justify-center text-sm" style="color:#${s.color}">
                            <i class="fa-solid ${s.icon}"></i>
                        </div>
                        <div class="font-bold">${s.name}</div>
                    </div>
                </td>
                <td class="p-4 text-center font-mono">${p.shares}</td>
                <td class="p-4 text-right text-sb-text2">${formatMoney(p.avgPrice.toFixed(2))}</td>
                <td class="p-4 text-right font-bold">${formatMoney(currentPrice)}</td>
                <td class="p-4 text-right ${profitClass} font-bold">
                    ${profit >= 0 ? '+' : ''}${formatMoney(profit.toFixed(0))} (${profitP.toFixed(1)}%)
                </td>
                <td class="p-4 text-right">
                    <button onclick="openModal('sell', '${s.id}')" class="bg-sb-danger/10 text-sb-danger border border-sb-danger/20 hover:bg-sb-danger hover:text-white px-3 py-1 rounded text-xs font-bold transition">SELL</button>
                </td>
            </tr>
            `;
        }).join('');
        
        tbody.innerHTML = html;
        document.getElementById('port-total').textContent = formatMoney(totalVal.toFixed(0));
        
        if (!hasItems) {
            tbody.innerHTML = '';
            empty.classList.remove('hidden');
        } else {
            empty.classList.add('hidden');
        }
    }

    // --- RENDER CHARTS ---
    function openChart(id) {
        selectedChartId = id;
        switchTab('charts');
    }

    function renderCharts() {
        // Sidebar List
        const list = document.getElementById('chart-list');
        list.innerHTML = STOCKS.map(s => {
            let isActive = s.id === selectedChartId;
            let activeClass = isActive ? 'bg-sb-accent text-sb-bg border-sb-accent' : 'bg-sb-card text-sb-text2 border-sb-border hover:border-sb-accent hover:text-white';
            let iconStyle = isActive ? '' : `style="color:#${s.color}"`;
            let bgIcon = isActive ? 'bg-white/20' : 'bg-sb-card2';
            
            return `<button onclick="openChart('${s.id}')" class="w-full text-left px-4 py-4 rounded-xl border font-bold text-sm flex items-center transition ${activeClass}">
                <div class="w-10 h-10 rounded-lg ${bgIcon} flex-shrink-0 flex items-center justify-center mr-3">
                    <i class="fa-solid ${s.icon} text-lg" ${iconStyle}></i>
                </div>
                <span class="truncate">${s.name}</span>
            </button>`;
        }).join('');
        
        let s = getStock(selectedChartId);
        let data = marketData[selectedChartId];
        if (!s || !data) return;
        
        document.getElementById('chart-title').innerText = s.name;
        document.getElementById('chart-sector').innerText = s.id;
        document.getElementById('chart-icon').innerHTML = `<i class="fa-solid ${s.icon}"></i>`;
        document.getElementById('chart-icon').style.color = '#' + s.color;
        document.getElementById('chart-price').innerText = formatMoney(data.current);
        
        let changeClass = data.lastChange >= 0 ? 'text-sb-success' : 'text-sb-danger';
        document.getElementById('chart-change').innerHTML = `<span class="${changeClass}">${data.lastChange}%</span>`;
        
        drawMainChart(data.history, '#' + s.color);
    }

    function drawMainChart(data, color) {
        const cvs = document.getElementById('main-chart');
        const ctx = cvs.getContext('2d');
        const rect = cvs.getBoundingClientRect();
        cvs.width = rect.width; cvs.height = rect.height;
        
        if (!data || data.length < 2) return;
        
        let min = Math.min(...data), max = Math.max(...data);
        let range = max - min || 1;
        let padTop = 20, padBot = 30;
        let h = cvs.height - padTop - padBot;
        
        ctx.clearRect(0,0,cvs.width,cvs.height);
        
        // Gradient fill
        let grad = ctx.createLinearGradient(0, 0, 0, cvs.height);
        grad.addColorStop(0, color + '66'); // 40% opacity
        grad.addColorStop(1, color + '00'); // 0% opacity
        
        // Path
        ctx.beginPath();
        let points = [];
        data.forEach((val, i) => {
            let x = (i / (data.length - 1)) * cvs.width;
            let y = padTop + h - ((val - min) / range * h);
            points.push({x,y});
            if (i===0) ctx.moveTo(x,y); else ctx.lineTo(x,y);
        });
        
        ctx.lineWidth = 3;
        ctx.strokeStyle = color;
        ctx.stroke();
        
        // Close for gradient
        ctx.lineTo(cvs.width, cvs.height);
        ctx.lineTo(0, cvs.height);
        ctx.closePath();
        ctx.fillStyle = grad;
        ctx.fill();
        
        // Grid lines (horizontal)
        ctx.lineWidth = 1;
        ctx.strokeStyle = '#ffffff11';
        ctx.beginPath();
        for(let i=1; i<4; i++) {
            let y = padTop + (h * (i/4));
            ctx.moveTo(0, y); ctx.lineTo(cvs.width, y);
        }
        ctx.stroke();
    }

    // --- MODAL ---
    function openModal(type, id) {
        console.log('openModal called', type, id);
        try {
            tradeType = type;
            selectedStockId = id;
            currentQty = 1;
            
            let s = getStock(id);
            let data = marketData[id] || { current: s.basePrice };
            
            document.getElementById('modal-title').innerText = type === 'buy' ? 'Buy Stock' : 'Sell Stock';
            document.getElementById('modal-stock-name').innerText = s.name;
            document.getElementById('modal-price').innerText = formatMoney(data.current) + " / share";
            document.getElementById('modal-icon').innerHTML = `<i class="fa-solid ${s.icon}"></i>`;
            document.getElementById('modal-icon').style.color = '#' + s.color;
            
            let btn = document.getElementById('modal-btn');
            if (type === 'buy') {
                btn.className = "w-full py-3 rounded-lg font-bold text-sb-bg bg-sb-success hover:bg-sb-success/80 transition";
                btn.innerText = "CONFIRM PURCHASE";
            } else {
                btn.className = "w-full py-3 rounded-lg font-bold text-sb-bg bg-sb-danger hover:bg-sb-danger/80 transition";
                btn.innerText = "CONFIRM SALE";
            }
            
            document.getElementById('modal-qty').value = 1;
            calcTotal();
            
            let modal = document.getElementById('modal');
            modal.classList.remove('hidden');
            modal.style.display = 'flex';

        } catch(e) {
            console.error('[StockBoard] openModal error:', e);
        }
    }

    function closeModal(e) {
        console.log('[StockBoard] closeModal called', e ? e.target.id : 'manual');
        if (e && e.target && e.target.id !== 'modal') return;
        let modal = document.getElementById('modal');
        modal.classList.add('hidden');
        modal.style.display = '';
        selectedStockId = null; // Clear selection
    }

    function adjQty(delta) {
        let newQ = currentQty + delta;
        if (newQ < 1) newQ = 1;
        
        // Calculate dynamic max
        let max = 999999;
        let s = getStock(selectedStockId);
        let data = marketData[selectedStockId] || { current: s.basePrice };
        let price = data.current;
        let feePct = {{Fee}};
        
        if (tradeType === 'buy') {
            // Max affordable — uses playerWallet synced from Lua client
            if (playerWallet > 0 && price > 0) {
                max = Math.floor(playerWallet / (price * (1 + feePct)));
            }
        } else {
            // Max own shares — can't sell more than you have
            let port = portfolio[selectedStockId];
            max = (port && port.shares > 0) ? port.shares : 0;
        }

        if (max < 1) max = 1;
        if (newQ > max) newQ = max;
        // if (newQ > {{MaxShares}}) newQ = {{MaxShares}}; // Override config cap if desired, or keep both? User said "max based on money".
        // Let's respect config cap too IF money allows more than cap.
        if (newQ > {{MaxShares}}) newQ = {{MaxShares}};
        
        currentQty = newQ;
        document.getElementById('modal-qty').value = currentQty;
        calcTotal();
    }

    function calcTotal() {
        let input = document.getElementById('modal-qty');
        let q = parseInt(input.value) || 0;
        if (q < 1) { q = 1; input.value = 1; } // Enforce min 1 on manual input
        currentQty = q;
        let data = marketData[selectedStockId];
        let price = data ? data.current : getStock(selectedStockId).basePrice;
        let sub = price * q;
        let fee = sub * {{Fee}};
        
        let total = tradeType === 'buy' ? sub + fee : sub - fee;
        document.getElementById('modal-total').innerText = formatMoney(total.toFixed(2));
    }

    function confirmTrade() {
        console.log('[StockBoard] confirmTrade', tradeType, selectedStockId, currentQty);
        let id_copy = selectedStockId; // Safety copy
        let qty_copy = String(currentQty);
        
        if (tradeType === 'buy') sb.buy(id_copy, qty_copy);
        else sb.sell(id_copy, qty_copy);
        
        closeModal();
    }

    // --- LUA BRIDGE IN ---
    function setMarketData(json) {
        let d = JSON.parse(json);
        // Merge updates instead of full replace to keep references if needed, but replace is fine here
        marketData = d;
        renderMarket();
        if (selectedStockId && !document.getElementById('modal').classList.contains('hidden')) calcTotal();
        if (!document.getElementById('page-portfolio').classList.contains('hidden')) renderPortfolio();
        if (!document.getElementById('page-charts').classList.contains('hidden')) renderCharts();
    }
    
    function setPortfolio(json) {
        portfolio = JSON.parse(json);
        renderPortfolio();
    }
    
    function setStats(json) {
        let s = JSON.parse(json);
        playerStats = s;
        document.getElementById('stat-invested').innerText = formatMoney(s.totalInvested);
        document.getElementById('stat-profit').innerText = formatMoney(s.totalProfit.toFixed(0));
        document.getElementById('stat-trades').innerText = s.trades;
        document.getElementById('stat-best').innerText = formatMoney(s.biggestTrade.toFixed(0));
        
        // Rank (only positive profit counts toward progression)
        let rank = RANKS[0];
        let nextRank = RANKS[1];
        let p = Math.max(0, s.totalProfit);
        
        for(let i=0; i<RANKS.length; i++) {
            if (p >= RANKS[i].threshold) {
                rank = RANKS[i];
                nextRank = RANKS[i+1];
            }
        }
        
        document.getElementById('rank-name').innerText = rank.name;
        document.getElementById('rank-icon').className = "fa-solid " + rank.icon;
        
        if (nextRank) {
            document.getElementById('rank-next-label').innerText = "Next: " + nextRank.name;
            document.getElementById('rank-progress-text').innerText = formatMoney(p.toFixed(0)) + " / " + formatMoney(nextRank.threshold);
            let pct = Math.min(100, Math.max(0, (p / nextRank.threshold) * 100));
            document.getElementById('rank-bar').style.width = pct + "%";
        } else {
            document.getElementById('rank-next-label').innerText = "Max Rank";
            document.getElementById('rank-progress-text').innerText = "";
            document.getElementById('rank-bar').style.width = "100%";
        }
    }
    
    function setLeaderboard(json) {
        let list = JSON.parse(json);
        const div = document.getElementById('lb-container');
        if (!list || list.length === 0) {
            div.innerHTML = '<div class="p-6 text-center text-sb-text2">No data</div>';
            return;
        }
        
        div.innerHTML = list.map(e => {
            let medal = `<span class="text-sb-text2 font-bold w-6">#${e.rank}</span>`;
            if (e.rank === 1) medal = `<i class="fa-solid fa-trophy text-yellow-400 w-6"></i>`;
            if (e.rank === 2) medal = `<i class="fa-solid fa-medal text-gray-300 w-6"></i>`;
            if (e.rank === 3) medal = `<i class="fa-solid fa-medal text-amber-600 w-6"></i>`;
            
            return `
            <div class="flex items-center justify-between p-4 border-b border-sb-border last:border-0 hover:bg-sb-card2 transition">
                <div class="flex items-center gap-4">
                    <div class="text-center">${medal}</div>
                    <div class="font-bold">${esc(e.name)}</div>
                </div>
                <div class="font-bold text-sb-accent">${e.value.toLocaleString()}</div>
            </div>
            `;
        }).join('');
    }
    
    function updateEvent(json) {
        let ev = JSON.parse(json);
        const ban = document.getElementById('market-event');
        if (!ev || !ev.text) {
            ban.classList.add('hidden');
            return;
        }
        
        ban.classList.remove('hidden');
        document.getElementById('event-text').innerText = ev.text;
        document.getElementById('event-icon').innerHTML = `<i class="fa-solid ${ev.icon}"></i>`;
        
        if (ev.type === 'positive') {
            ban.className = "mb-6 rounded-xl p-4 border border-l-4 flex items-center gap-4 animate-[slideUp_0.3s_ease] bg-sb-success/10 border-sb-success text-sb-success";
        } else {
            ban.className = "mb-6 rounded-xl p-4 border border-l-4 flex items-center gap-4 animate-[slideUp_0.3s_ease] bg-sb-danger/10 border-sb-danger text-sb-danger";
        }
    }
    
    const LB_ACTIVE = ['bg-sb-accent', 'text-sb-bg', 'border-sb-accent'];
    const LB_INACTIVE = ['bg-sb-card', 'border-sb-border', 'hover:border-sb-accent'];

    function reqLb(cat) {
        ['totalProfit', 'trades'].forEach(c => {
            let btn = document.getElementById('lb-btn-' + c);
            if (!btn) return;
            if (c === cat) {
                LB_INACTIVE.forEach(cl => btn.classList.remove(cl));
                LB_ACTIVE.forEach(cl => btn.classList.add(cl));
            } else {
                LB_ACTIVE.forEach(cl => btn.classList.remove(cl));
                LB_INACTIVE.forEach(cl => btn.classList.add(cl));
            }
        });
        sb.reqLb(cat);
    }

document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') sb.close();
});
</script>
</body>
</html>
]==]

function StockBoard.OpenMenu()
    if IsValid(StockBoard.MenuFrame) then
        StockBoard.MenuFrame:Close()
        StockBoard.MenuFrame = nil
    end

    -- Request Data
    net.Start("StockBoard_RequestData")
    net.SendToServer()

    local frame = vgui.Create("DFrame")
    frame:SetSize(ScrW(), ScrH())
    frame:SetPos(0, 0)
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:SetDraggable(false)
    frame:MakePopup()
    frame:DockPadding(0,0,0,0)
    frame.Paint = function() end
    StockBoard.MenuFrame = frame

    hook.Add("PlayerBindPress", "StockBoard_BlockESC", function(_, bind)
        if string.find(bind, "cancelselect") and IsValid(frame) then
            frame:Close()
            return true
        end
    end)

    frame.OnClose = function()
        hook.Remove("PlayerBindPress", "StockBoard_BlockESC")
    end

    local dhtml = vgui.Create("DHTML", frame)
    dhtml:Dock(FILL)
    dhtml:SetAllowLua(true)
    StockBoard.DHTML = dhtml

    -- Bridge
    dhtml:AddFunction("sb", "close", function()
        if IsValid(frame) then
            frame:Close()
            timer.Simple(0, function() gui.HideGameUI() end)
        end
    end)
    
    dhtml:AddFunction("sb", "buy", function(id, qty)
        print("[StockBoard] Client Requesting BUY: " .. tostring(id) .. " x" .. tostring(qty))
        net.Start("StockBoard_Buy")
            net.WriteString(id)
            net.WriteInt(tonumber(qty) or 1, 32)
        net.SendToServer()
    end)
    
    dhtml:AddFunction("sb", "sell", function(id, qty)
        print("[StockBoard] Client Requesting SELL: " .. tostring(id) .. " x" .. tostring(qty))
        net.Start("StockBoard_Sell")
            net.WriteString(id)
            net.WriteInt(tonumber(qty) or 1, 32)
        net.SendToServer()
    end)
    
    dhtml:AddFunction("sb", "reqLb", function(cat)
        net.Start("StockBoard_RequestLeaderboard")
            net.WriteString(cat)
        net.SendToServer()
    end)

    dhtml:SetHTML(StockBoard.BuildHTML())
    dhtml:RequestFocus()
end

function StockBoard.BuildHTML()
    local html = HTML_TEMPLATE
    
    -- Injections simples
    for k, v in pairs(StockBoard.Config.Theme) do html = string.Replace(html, "{{"..k.."}}", v) end
    for k, v in pairs(StockBoard.Config.UI) do html = string.Replace(html, "{{"..k.."}}", v) end
    html = string.Replace(html, "{{CurrencySymbol}}", StockBoard.Config.CurrencySymbol)
    html = string.Replace(html, "{{MaxShares}}", tostring(StockBoard.Config.MaxShares))
    html = string.Replace(html, "{{Fee}}", tostring(StockBoard.Config.TransactionFee))

    -- Injections JSON
    html = string.Replace(html, "{{ConfigJSON}}", util.TableToJSON(StockBoard.Config))
    html = string.Replace(html, "{{StocksJSON}}", util.TableToJSON(StockBoard.Config.Stocks))
    html = string.Replace(html, "{{RanksJSON}}", util.TableToJSON(StockBoard.Config.Ranks))
    
    return html
end

-- Helper to send data to JS
function StockBoard.JS(func, data)
    if not IsValid(StockBoard.DHTML) then return end
    local json = util.TableToJSON(data)
    json = string.Replace(json, "'", "\\'") -- Escape simple quotes
    StockBoard.DHTML:QueueJavascript(func .. "('" .. json .. "')")
end

-- Receivers
-- Push current wallet to JS (read directly from DarkRP client-side)
function StockBoard.SyncWallet()
    if not IsValid(StockBoard.DHTML) then return end
    local money = 0
    local ply = LocalPlayer()
    if ply.getDarkRPVar then money = ply:getDarkRPVar("money") or 0
    elseif ply.getDarkRPvar then money = ply:getDarkRPvar("money") or 0
    elseif ply.GetMoney then money = ply:GetMoney() or 0
    end
    StockBoard.DHTML:QueueJavascript("playerWallet = " .. tostring(money) .. ";")
end

net.Receive("StockBoard_SendMarket", function()
    local market = net.ReadTable()
    local event = net.ReadTable()
    StockBoard.MarketData = market
    StockBoard.JS("setMarketData", market)
    StockBoard.JS("updateEvent", event)
    StockBoard.SyncWallet()
end)

net.Receive("StockBoard_Notify", function()
    local msg = net.ReadString()
    local type = net.ReadString()
    StockBoard.JS("bridgeNotify", {msg = msg, type = type})
end)

net.Receive("StockBoard_SendPortfolio", function()
    local port = net.ReadTable()
    StockBoard.MyPortfolio = port
    StockBoard.JS("setPortfolio", port)
end)

net.Receive("StockBoard_SendPlayerStats", function()
    local stats = net.ReadTable()
    StockBoard.MyStats = stats
    StockBoard.JS("setStats", stats)
    StockBoard.SyncWallet()
end)

net.Receive("StockBoard_SendLeaderboard", function()
    local cat = net.ReadString()
    local top = net.ReadTable()
    -- On pourrait utiliser myRank/myValue aussi mais le JS gere juste le top 10 pour l'instant
    StockBoard.JS("setLeaderboard", top)
end)

net.Receive("StockBoard_PriceTick", function()
    local updates = net.ReadTable()
    -- Partial update of local state
    for id, u in pairs(updates) do
        if StockBoard.MarketData[id] then
            StockBoard.MarketData[id].current = u.c
            StockBoard.MarketData[id].lastChange = u.l
            table.insert(StockBoard.MarketData[id].history, u.c)
            if #StockBoard.MarketData[id].history > StockBoard.Config.PriceHistoryLength then
                table.remove(StockBoard.MarketData[id].history, 1)
            end
        end
    end
    StockBoard.JS("setMarketData", StockBoard.MarketData)
end)

net.Receive("StockBoard_MarketEvent", function()
    local ev = net.ReadTable()
    StockBoard.JS("updateEvent", ev)
end)

-- Chat commands
hook.Add("OnPlayerChat", "StockBoard_Chat", function(ply, text)
    if ply ~= LocalPlayer() then return end
    text = string.lower(string.Trim(text))
    for _, cmd in ipairs(StockBoard.Config.ChatCommands) do
        if text == cmd then
            StockBoard.OpenMenu()
            return true
        end
    end
end)

concommand.Add("stockboard_menu", function() StockBoard.OpenMenu() end)