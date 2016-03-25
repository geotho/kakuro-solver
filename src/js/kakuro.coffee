$ ->

  loadKakuro('kakuros/2016-01-08.txt')
#   loadKakuro('kakuros/test.txt')

  # kakuroRactive = new Ractive
  #   el: '#kakuro-container'
  #   template: '#kakuro-template'
  #   data:
  #     poop: 'test1'
  #     shoop: 'test2'

loadKakuro = (url) ->
  $.get(url, (data) ->
    k = new Kakuro(data)
    window.k = k
    window.b = k.makeCSP()
    console.log window.b
    # csp.solve(window.b)
    k.clear()
    # k.map((cell) -> console.log "x", cell.x, "y", cell.y, "domain", k.domain(cell.x, cell.y) if cell.type() == "NUMBER")
    $('#kakuro-container').html(k.toHtml())
  )

powersum = () ->
  return window.ps if window.ps?

  sums = ([] for x in [0..45])
  l = [1..9]
  max = 1 << l.length
  for bitmask in [1...max]
    cur = []
    for j in [0..l.length]
      if ((bitmask & (1 << j)) > 0)
        cur.push(l[j])
    total = cur.reduce (x,y) -> x+y
    sums[total].push(cur)
  window.ps = sums
  sums

ways = (total, length) ->
  powersum()[total].filter((x) -> x.length == length)

waysIncludes = (total, length, includes...) ->
  ws = ways(total, length)
  filteredWays = []
  inner = (way, includes) ->
    for i in includes
      if !way.includes(i)
        return false
    return true
  #predicate true iff all items in includes are in way
  # ways.filter (way) -> includes.reduce((prev, curr) -> prev && way.includes(curr), )
  for way in ws
    if inner(way, includes)
      filteredWays.push(way)

  filteredWays


toBitmask = (arr) ->
  mask = 0
  for i in arr
    mask |= (1 << i-1)
  mask

toArray = (bitmask) ->
  arr = []
  for j in [1..9]
    if ((bitmask & (1 << j-1)) > 0)
      arr.push(j)
  arr

intersect = (arr1, arr2) -> toArray(toBitmask(arr1) & toBitmask(arr2))

neq = (one, two) -> one != two

arrayExcept = (arr, idx) ->
  res = arr[..]
  res.splice idx, 1
  res

permute = (arr) ->
  return [[]] if arr.length == 0

  permutations = (for value,idx in arr
    [value].concat perm for perm in permute arrayExcept arr, idx)

  # Flatten the array before returning it.
  [].concat permutations...

vals = (numOne, numTwo) -> (x, y) -> x != numOne || y == numTwo

class Kakuro
  constructor: (text) ->
    cells = []
    for line, y in text.split('\n')
      row = []
      for cell, x in line.split(',')
        c = new Cell(cell, x, y)
        row.push(c)
      cells.push(row)
    cells.pop()
    @cells = cells
    console.log(@cells)
    for line, y in @cells
      for cell, x in line
        if cell.isTotal()
          cell.rowTotal = cell
          cell.colTotal = cell
        else if cell.isNumber()
          cell.rowTotal = @getCell(x-1, y).rowTotal
          cell.colTotal = @getCell(x, y-1).colTotal
          cell.domain = @domain(x,y)
          cell.constrains = (x for x in @getRow(x, y)[1..].concat(@getCol(x, y)[1..]) when x != cell)
    window.k = @

  width: -> @cells[0].length

  height: -> @cells.length

  getCell: (x, y) ->
    console.assert(x >= 0)
    console.assert(y >= 0)
    console.assert(x < @width())
    console.assert(y < @height())

    return @cells[y][x]

  map: (f) ->
    for row, y in @cells
      for cell, x in row
        f(cell)

  clear: ->
    for row, y in @cells
      for cell, x in row
        if cell.type() == 'NUMBER'
          cell.raw = ""

  toHtml: ->
    html = '<table class="col-sm-12">'
    html += '<tr>'
    html += '<td></td>'
    for i in [0...@width()]
      html += "<td>#{i}</td>"
    html += '</tr>'
    for row, j in @cells
      html += '<tr>'
      html += "<td>#{j}</td>"
      for cell in row
        html += cell.render()
      html += '</tr>'
    html += '</table>'

  # column x, row y. Top left is (0, 0)
  rowLength: (origX, origY) ->
    return @getCell(origX, origY).rowLength if @getCell(origX, origY).rowLength?

    totalCell = @rowTotal(origX, origY)
    x = totalCell.x
    y = totalCell.y

    len = totalCell.x+1
    c = @getCell(len, y)

    while c.isNumber()
      c = @getCell(++len, y)
      break unless c

    @getCell(x, y).rowLength = len - x - 1
    return len - x - 1

  # column x, row y. Top left is (0, 0)
  colLength: (origX, origY) ->
    return @getCell(origX, origY).colLength if @getCell(origX, origY).colLength?

    totalCell = @colTotal(origX,origY)
    x = totalCell.x
    y = totalCell.y

    len = totalCell.y+1
    c = @getCell(x, len)

    while c.isNumber()
      r = @cells[++len]
      break unless r
      c = r[x]

    @getCell(x, y).colLength = len - y - 1
    return len - y - 1

  # rowTotal searches left from column x, row y returning the first total cell found.
  rowTotal: (x, y) -> @getCell(x, y).rowTotal

  colTotal: (x, y) -> @getCell(x, y).colTotal

  domain: (x, y) ->
    rowPoss = ways(@rowTotal(x, y).topRight(), @rowLength(x, y)).reduce(((p, q) -> p.concat(q)), [])
    colPoss = ways(@colTotal(x, y).bottomLeft(), @colLength(x, y)).reduce(((p, q) -> p.concat(q)), [])

    intersect(rowPoss, colPoss)

  makeCSP: ->
    variables = {}
    constraints = []
    for row in @cells
      for cell in row
        if cell.isTotal()
          c = @makeConstraints(cell.x, cell.y)

          # c["constraints"] might be too big to splat.
          # constraints.concat(c["constraints"]...)
          constraints.push(x) for x in c["constraints"]
          if cell.isColTotal()
            variables[cell.string()+"c"] = c["colDomain"]
          if cell.isRowTotal()
            variables[cell.string()+"r"] = c["rowDomain"]
        if cell.isNumber()
          variables[cell.string()] = cell.domain

    csp = {}
    csp["variables"] = variables
    csp["constraints"] = constraints
    csp["cb"] = (assigned, unassigned, csp) ->
      console.log("assigned=", assigned, "unassigned=", unassigned)
    csp["timeStep"] = 1

    return csp


  makeConstraints: (x, y) ->
    c = @getCell(x, y)
    console.assert(c.isTotal())
    constraints = []

    if c.isRowTotal()

      rowAdd = @makeRowAddConstraints(x, y)
      rowDomain = rowAdd["domain"]
      rowConstraints = rowAdd["constraints"]
      constraints = constraints
          .concat(@makeRowNeqConstraints(x, y))
          .concat(rowConstraints)

    if c.isColTotal()
      colAdd = @makeColAddConstraints(x, y)
      colDomain = colAdd["domain"]
      colConstraints = colAdd["constraints"]
      constraints = constraints
          .concat(@makeColNeqConstraints(x, y))
          .concat(colConstraints)

    console.log("Created #{constraints.length} constraints for #{c.string()}")
    return (
      "constraints": constraints
      "rowDomain": rowDomain
      "colDomain": colDomain
    )

  makeRowNeqConstraints: (x, y) ->
    totalCell = @rowTotal(x,y)
    x = totalCell.x
    y = totalCell.y

    constraints = []
    len = @rowLength(x, y)
    for i in [x+1...x+len]
      for j in [i+1..x+len]
        constraints.push([@cells[y][i].string(), @cells[y][j].string(), neq])
    return constraints

  makeColNeqConstraints: (x, y) ->
    totalCell = @colTotal(x,y)
    x = totalCell.x
    y = totalCell.y

    constraints = []
    len = @colLength(x, y)
    for i in [y+1...y+len]
      for j in [i+1..y+len]
        constraints.push([@cells[i][x].string(), @cells[j][x].string(), neq])
    return constraints

  makeRowAddConstraints: (x, y) ->
    totalCell = @rowTotal(x,y)
    x = totalCell.x
    y = totalCell.y

    len = @rowLength(x, y)
    waysArr = ways(totalCell.topRight(), len)

    if waysArr.length == 1
        # all rows and columns of length 9 sum to 45, so the not equal constraints are sufficient
        return (
            "domain": [0]
            "constraints": []
        )

    allConstraints = []
    domain = []

    for way, k in waysArr
      permutations = permute(way)
      l = permutations.length
      for perm, j in permutations
        constraints = []
        valid = true
        for v, i in perm
          c = @getCell(x+i+1, y)
          if c.domain.indexOf(v) == -1
            valid = false
            break
          # console.log("Adding constraints: #{totalCell.string()} != #{k*l+j} || #{c.string()} == #{v}")
          constraints.push([totalCell.string()+"r", c.string(), vals(k*l+j, v)])

        if valid
          domain.push(k*l+j)
          allConstraints.push(constraints...)

    # console.log("Produced #{allConstraints.length} row constraints for #{totalCell.string()}")
    return (
      "domain": domain
      "constraints": allConstraints
    )

  makeColAddConstraints: (x, y) ->
    totalCell = @colTotal(x,y)
    x = totalCell.x
    y = totalCell.y

    len = @colLength(x, y)
    waysArr = ways(totalCell.bottomLeft(), len)

    if waysArr.length == 1
        # all rows and columns of length 9 sum to 45, so the not equal constraints are sufficient
        return (
            "domain": [0]
            "constraints": []
        )

    allConstraints = []
    domain = []

    for way, k in waysArr
      permutations = permute(way)
      l = permutations.length
      for perm, j in permutations
        constraints = []
        valid = true
        for v, i in perm
          c = @getCell(x, y+i+1)
          if c.domain.indexOf(v) == -1
            valid = false
            break
          # console.log("Adding constraints: #{totalCell.string()} != #{k*l+j} || #{c.string()} == #{v}")
          constraints.push([totalCell.string()+"c", c.string(), vals(k*l+j, v)])
        if valid
          domain.push(k*l+j)
          allConstraints.push(constraints...)

    # console.log("Produced #{allConstraints.length} col constraints for #{totalCell.string()}")
    return (
      "domain": domain
      "constraints": allConstraints
    )

  # solveItr inserts one number into the kakuro by:
  #   1) first looking for any domain of size one.
  #   2) finding connecting nodes which must be a particular value.
  #   3) backtracking search to find contradictions to eliminate elements from domains.
  solveItr: ->
    if @solveSingleDomain()
      @renderOnPage()
      return true


  # solveSingleDomain finds a cell with domain of size one and inserts that value.
  # Returns true iff a cell with single domain is found.
  solveSingleDomain: ->
    for row in @cells
      for cell in row
        if cell.isNumber()
          if cell.domain.length == 1 && cell.raw == ""
            @insert(cell.x, cell.y, cell.domain[0])
            return true
    return false

  insert: (x, y, val) ->
    cell = @getCell(x, y)
    console.assert(cell.domain.includes(val), "inserting into #{cell.string()} value #{val} but not in domain")

    cell.raw = "" + val

    #new domain is the inserection of the waysIncludes and the current domain
    row = @getRow(x, y)
    rowTotal = row[0].topRight()
    rowWays = waysIncludes(rowTotal, row.length-1, @rowInserted(x,y)...).reduce( (a, b) -> (a.concat(b)))

    col = @getCol(x, y)
    colTotal = col[0].bottomLeft()
    colWays = waysIncludes(colTotal, col.length-1, @colInserted(x,y)...).reduce( (a, b) -> (a.concat(b)))

    for cell in row[1..]
      if !((cell.x == x) && (cell.y == y))
        idx = cell.domain.indexOf(val)
        isIn = idx >= 0
        if isIn
          cell.domain.splice(cell.domain.indexOf(val), 1)
        cell.domain = intersect(cell.domain, rowWays)
    for cell in col[1..]
      if !((cell.x == x) && (cell.y == y))
        idx = cell.domain.indexOf(val)
        isIn = idx >= 0
        if isIn
          cell.domain.splice(cell.domain.indexOf(val), 1)
        cell.domain = intersect(cell.domain, colWays)

  getRow: (x, y) ->
    rowTotal = @rowTotal(x, y)
    x = rowTotal.x
    y = rowTotal.y
    rowLength = @rowLength(x, y)
    row = [rowTotal]
    for i in [1..rowLength]
      row.push(@getCell(x+i, y))
    row

  getCol: (x, y) ->
    colTotal = @colTotal(x, y)
    x = colTotal.x
    y = colTotal.y
    colLength = @colLength(x, y)
    col = [colTotal]
    for i in [1..colLength]
      col.push(@getCell(x, y+i))
    col

  rowInserted: (x, y) -> (cell.number() for cell in @getRow(x, y)[1..] when cell.raw != "")
  colInserted: (x, y) -> (cell.number() for cell in @getCol(x, y)[1..] when cell.raw != "")

  renderOnPage: -> $('#kakuro-container').html(a.toHtml())

class Cell
  constructor: (text, x, y, domain) ->
    @raw = text
    @x = x
    @y = y
    @domain = domain

  type: ->
    if @raw == 'x'
      return 'BLANK'
    if @raw.includes('-')
      return 'TOTAL'
    return 'NUMBER'

  render: ->
    if @type() == 'BLANK'
      return '<td class="blank"></td>'
    if @type() == 'TOTAL'
      return '<td class="total">' +
        '<table>' +
          '<tr>' + '<td>' + @topRightStr() + '</td>' + '</tr>' +
          '<tr>' + '<td>' + @bottomLeftStr() + '</td>' + '</tr>' +
        '</table>' +
      '</td>'
    return '<td class="number">' + @raw + '</td>'

  topRight: ->
    s = parseInt @raw.split('-')[1]
    if !!s then parseInt s else 0

  bottomLeft: ->
    s = @raw.split('-')[0]
    if !!s then parseInt s else 0

  topRightStr: ->
    if @topRight() == 0 then "" else @topRight() + "&rarr;"

  bottomLeftStr: ->
    if @bottomLeft() == 0 then "" else @bottomLeft() + "&darr;"

  number: ->
    parseInt(@raw)

  string: ->
    "(#{@x},#{@y})"

  isTotal: ->
    @type() == 'TOTAL'

  isNumber: ->
    @type() == 'NUMBER'

  isColTotal: ->
    @isTotal() && @bottomLeft() != 0

  isRowTotal: ->
    @isTotal() && @topRight() != 0
