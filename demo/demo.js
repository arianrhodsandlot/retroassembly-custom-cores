const core = new URLSearchParams(location.search).get('core')

const addRomButton = document.querySelector('#add-rom')
const addBiosButton = document.querySelector('#add-bios')
const runButton = document.querySelector('#run')
const select = document.querySelector('#core')

const rom = []
async function addRom () {
  const [fileHandle] = await showOpenFilePicker()
  const file = await fileHandle.getFile()
  rom.push({ fileName: file.name, fileContent: file })
}

const bios = []
async function addBios() {
  const [fileHandle] = await showOpenFilePicker()
  const file = await fileHandle.getFile()
  bios.push(file)
}

async function run() {
  await Nostalgist.launch({ core, rom, bios })
}

function onSelectCore() {
  location.replace(select.value ? `?core=${encodeURIComponent(select.value)}` : location.pathname)
}

select.addEventListener('change', onSelectCore)
addRomButton.addEventListener('click', addRom)
addBiosButton.addEventListener('click', addBios)
runButton.addEventListener('click', run)

if (core) {
  select.value = core
  addRomButton.hidden = false
  addBiosButton.hidden = false
  runButton.hidden = false
}

Nostalgist.configure({
  resolveCoreJs(core) {
    return '/dist/cores/' + core + '_libretro.js'
  },

  resolveCoreWasm(core) {
    return '/dist/cores/' + core + '_libretro.wasm'
  },
})
