// Generated by CoffeeScript 1.10.0
(function() {
  var Cell, Kakuro, arrayExcept, intersect, loadKakuro, neq, permute, powersum, toArray, toBitmask, vals, ways, waysIncludes,
    slice = [].slice;

  $(function() {
    return loadKakuro('kakuros/2016-01-08.txt');
  });

  loadKakuro = function(url) {
    return $.get(url, function(data) {
      var k;
      k = new Kakuro(data);
      window.k = k;
      window.b = k.makeCSP();
      console.log(window.b);
      k.clear();
      return k.renderOnPage();
    });
  };

  powersum = function() {
    var bitmask, cur, j, l, m, max, n, ref, ref1, sums, total, x;
    if (window.ps != null) {
      return window.ps;
    }
    sums = (function() {
      var m, results;
      results = [];
      for (x = m = 0; m <= 45; x = ++m) {
        results.push([]);
      }
      return results;
    })();
    l = [1, 2, 3, 4, 5, 6, 7, 8, 9];
    max = 1 << l.length;
    for (bitmask = m = 1, ref = max; 1 <= ref ? m < ref : m > ref; bitmask = 1 <= ref ? ++m : --m) {
      cur = [];
      for (j = n = 0, ref1 = l.length; 0 <= ref1 ? n <= ref1 : n >= ref1; j = 0 <= ref1 ? ++n : --n) {
        if ((bitmask & (1 << j)) > 0) {
          cur.push(l[j]);
        }
      }
      total = cur.reduce(function(x, y) {
        return x + y;
      });
      sums[total].push(cur);
    }
    window.ps = sums;
    return sums;
  };

  ways = function(total, length) {
    return powersum()[total].filter(function(x) {
      return x.length === length;
    });
  };

  waysIncludes = function() {
    var filteredWays, includes, inner, len1, length, m, total, way, ws;
    total = arguments[0], length = arguments[1], includes = 3 <= arguments.length ? slice.call(arguments, 2) : [];
    ws = ways(total, length);
    filteredWays = [];
    inner = function(way, includes) {
      var i, len1, m;
      for (m = 0, len1 = includes.length; m < len1; m++) {
        i = includes[m];
        if (!way.includes(i)) {
          return false;
        }
      }
      return true;
    };
    for (m = 0, len1 = ws.length; m < len1; m++) {
      way = ws[m];
      if (inner(way, includes)) {
        filteredWays.push(way);
      }
    }
    return filteredWays;
  };

  toBitmask = function(arr) {
    var i, len1, m, mask;
    mask = 0;
    for (m = 0, len1 = arr.length; m < len1; m++) {
      i = arr[m];
      mask |= 1 << i - 1;
    }
    return mask;
  };

  toArray = function(bitmask) {
    var arr, j, m;
    arr = [];
    for (j = m = 1; m <= 9; j = ++m) {
      if ((bitmask & (1 << j - 1)) > 0) {
        arr.push(j);
      }
    }
    return arr;
  };

  intersect = function(arr1, arr2) {
    return toArray(toBitmask(arr1) & toBitmask(arr2));
  };

  neq = function(one, two) {
    return one !== two;
  };

  arrayExcept = function(arr, idx) {
    var res;
    res = arr.slice(0);
    res.splice(idx, 1);
    return res;
  };

  permute = function(arr) {
    var idx, perm, permutations, ref, value;
    if (arr.length === 0) {
      return [[]];
    }
    permutations = (function() {
      var len1, m, results;
      results = [];
      for (idx = m = 0, len1 = arr.length; m < len1; idx = ++m) {
        value = arr[idx];
        results.push((function() {
          var len2, n, ref, results1;
          ref = permute(arrayExcept(arr, idx));
          results1 = [];
          for (n = 0, len2 = ref.length; n < len2; n++) {
            perm = ref[n];
            results1.push([value].concat(perm));
          }
          return results1;
        })());
      }
      return results;
    })();
    return (ref = []).concat.apply(ref, permutations);
  };

  vals = function(numOne, numTwo) {
    return function(x, y) {
      return x !== numOne || y === numTwo;
    };
  };

  Kakuro = (function() {
    function Kakuro(text) {
      var c, cell, cells, len1, len2, len3, len4, line, m, n, o, ref, ref1, ref2, row, t, x, y;
      cells = [];
      ref = text.split('\n');
      for (y = m = 0, len1 = ref.length; m < len1; y = ++m) {
        line = ref[y];
        row = [];
        ref1 = line.split(',');
        for (x = n = 0, len2 = ref1.length; n < len2; x = ++n) {
          cell = ref1[x];
          c = new Cell(cell, x, y);
          row.push(c);
        }
        cells.push(row);
      }
      cells.pop();
      this.cells = cells;
      console.log(this.cells);
      ref2 = this.cells;
      for (y = o = 0, len3 = ref2.length; o < len3; y = ++o) {
        line = ref2[y];
        for (x = t = 0, len4 = line.length; t < len4; x = ++t) {
          cell = line[x];
          if (cell.isTotal()) {
            cell.rowTotal = cell;
            cell.colTotal = cell;
          } else if (cell.isNumber()) {
            cell.rowTotal = this.getCell(x - 1, y).rowTotal;
            cell.colTotal = this.getCell(x, y - 1).colTotal;
            cell.domain = this.domain(x, y);
            cell.constrains = (function() {
              var len5, ref3, results, u;
              ref3 = this.getRow(x, y).slice(1).concat(this.getCol(x, y).slice(1));
              results = [];
              for (u = 0, len5 = ref3.length; u < len5; u++) {
                x = ref3[u];
                if (x !== cell) {
                  results.push(x);
                }
              }
              return results;
            }).call(this);
          }
        }
      }
      this.markGraphSolvable();
      window.k = this;
    }

    Kakuro.prototype.width = function() {
      return this.cells[0].length;
    };

    Kakuro.prototype.height = function() {
      return this.cells.length;
    };

    Kakuro.prototype.getCell = function(x, y) {
      console.assert(x >= 0);
      console.assert(y >= 0);
      console.assert(x < this.width());
      console.assert(y < this.height());
      return this.cells[y][x];
    };

    Kakuro.prototype.map = function(f) {
      var cell, len1, m, ref, results, row, x, y;
      ref = this.cells;
      results = [];
      for (y = m = 0, len1 = ref.length; m < len1; y = ++m) {
        row = ref[y];
        results.push((function() {
          var len2, n, results1;
          results1 = [];
          for (x = n = 0, len2 = row.length; n < len2; x = ++n) {
            cell = row[x];
            results1.push(f(cell));
          }
          return results1;
        })());
      }
      return results;
    };

    Kakuro.prototype.clear = function() {
      var cell, len1, m, ref, results, row, x, y;
      ref = this.cells;
      results = [];
      for (y = m = 0, len1 = ref.length; m < len1; y = ++m) {
        row = ref[y];
        results.push((function() {
          var len2, n, results1;
          results1 = [];
          for (x = n = 0, len2 = row.length; n < len2; x = ++n) {
            cell = row[x];
            if (cell.type() === 'NUMBER') {
              results1.push(cell.raw = "");
            } else {
              results1.push(void 0);
            }
          }
          return results1;
        })());
      }
      return results;
    };

    Kakuro.prototype.toHtml = function() {
      var cell, html, i, j, len1, len2, m, n, o, ref, ref1, row;
      html = '<table class="col-sm-12">';
      html += '<tr>';
      html += '<td></td>';
      for (i = m = 0, ref = this.width(); 0 <= ref ? m < ref : m > ref; i = 0 <= ref ? ++m : --m) {
        html += "<td>" + i + "</td>";
      }
      html += '</tr>';
      ref1 = this.cells;
      for (j = n = 0, len1 = ref1.length; n < len1; j = ++n) {
        row = ref1[j];
        html += '<tr>';
        html += "<td>" + j + "</td>";
        for (o = 0, len2 = row.length; o < len2; o++) {
          cell = row[o];
          html += cell.render();
        }
        html += '</tr>';
      }
      return html += '</table>';
    };

    Kakuro.prototype.rowLength = function(origX, origY) {
      var c, len, totalCell, x, y;
      if (this.getCell(origX, origY).rowLength != null) {
        return this.getCell(origX, origY).rowLength;
      }
      totalCell = this.rowTotal(origX, origY);
      x = totalCell.x;
      y = totalCell.y;
      len = totalCell.x + 1;
      c = this.getCell(len, y);
      while (c.isNumber()) {
        c = this.cells[y][++len];
        if (!c) {
          break;
        }
      }
      this.getCell(x, y).rowLength = len - x - 1;
      return len - x - 1;
    };

    Kakuro.prototype.colLength = function(origX, origY) {
      var c, len, r, totalCell, x, y;
      if (this.getCell(origX, origY).colLength != null) {
        return this.getCell(origX, origY).colLength;
      }
      totalCell = this.colTotal(origX, origY);
      x = totalCell.x;
      y = totalCell.y;
      len = totalCell.y + 1;
      c = this.getCell(x, len);
      while (c.isNumber()) {
        r = this.cells[++len];
        if (!r) {
          break;
        }
        c = r[x];
      }
      this.getCell(x, y).colLength = len - y - 1;
      return len - y - 1;
    };

    Kakuro.prototype.rowTotal = function(x, y) {
      return this.getCell(x, y).rowTotal;
    };

    Kakuro.prototype.colTotal = function(x, y) {
      return this.getCell(x, y).colTotal;
    };

    Kakuro.prototype.domain = function(x, y) {
      var colPoss, rowPoss;
      rowPoss = ways(this.rowTotal(x, y).topRight(), this.rowLength(x, y)).reduce((function(p, q) {
        return p.concat(q);
      }), []);
      colPoss = ways(this.colTotal(x, y).bottomLeft(), this.colLength(x, y)).reduce((function(p, q) {
        return p.concat(q);
      }), []);
      return intersect(rowPoss, colPoss);
    };

    Kakuro.prototype.makeCSP = function() {
      var c, cell, constraints, csp, len1, len2, len3, m, n, o, ref, ref1, row, variables, x;
      variables = {};
      constraints = [];
      ref = this.cells;
      for (m = 0, len1 = ref.length; m < len1; m++) {
        row = ref[m];
        for (n = 0, len2 = row.length; n < len2; n++) {
          cell = row[n];
          if (cell.isTotal()) {
            c = this.makeConstraints(cell.x, cell.y);
            ref1 = c["constraints"];
            for (o = 0, len3 = ref1.length; o < len3; o++) {
              x = ref1[o];
              constraints.push(x);
            }
            if (cell.isColTotal()) {
              variables[cell.string() + "c"] = c["colDomain"];
            }
            if (cell.isRowTotal()) {
              variables[cell.string() + "r"] = c["rowDomain"];
            }
          }
          if (cell.isNumber()) {
            variables[cell.string()] = cell.domain;
          }
        }
      }
      csp = {};
      csp["variables"] = variables;
      csp["constraints"] = constraints;
      csp["cb"] = function(assigned, unassigned, csp) {
        return console.log("assigned=", assigned, "unassigned=", unassigned);
      };
      csp["timeStep"] = 1;
      return csp;
    };

    Kakuro.prototype.makeConstraints = function(x, y) {
      var c, colAdd, colConstraints, colDomain, constraints, rowAdd, rowConstraints, rowDomain;
      c = this.getCell(x, y);
      console.assert(c.isTotal());
      constraints = [];
      if (c.isRowTotal()) {
        rowAdd = this.makeRowAddConstraints(x, y);
        rowDomain = rowAdd["domain"];
        rowConstraints = rowAdd["constraints"];
        constraints = constraints.concat(this.makeRowNeqConstraints(x, y)).concat(rowConstraints);
      }
      if (c.isColTotal()) {
        colAdd = this.makeColAddConstraints(x, y);
        colDomain = colAdd["domain"];
        colConstraints = colAdd["constraints"];
        constraints = constraints.concat(this.makeColNeqConstraints(x, y)).concat(colConstraints);
      }
      console.log("Created " + constraints.length + " constraints for " + (c.string()));
      return {
        "constraints": constraints,
        "rowDomain": rowDomain,
        "colDomain": colDomain
      };
    };

    Kakuro.prototype.makeRowNeqConstraints = function(x, y) {
      var constraints, i, j, len, m, n, ref, ref1, ref2, ref3, totalCell;
      totalCell = this.rowTotal(x, y);
      x = totalCell.x;
      y = totalCell.y;
      constraints = [];
      len = this.rowLength(x, y);
      for (i = m = ref = x + 1, ref1 = x + len; ref <= ref1 ? m < ref1 : m > ref1; i = ref <= ref1 ? ++m : --m) {
        for (j = n = ref2 = i + 1, ref3 = x + len; ref2 <= ref3 ? n <= ref3 : n >= ref3; j = ref2 <= ref3 ? ++n : --n) {
          constraints.push([this.cells[y][i].string(), this.cells[y][j].string(), neq]);
        }
      }
      return constraints;
    };

    Kakuro.prototype.makeColNeqConstraints = function(x, y) {
      var constraints, i, j, len, m, n, ref, ref1, ref2, ref3, totalCell;
      totalCell = this.colTotal(x, y);
      x = totalCell.x;
      y = totalCell.y;
      constraints = [];
      len = this.colLength(x, y);
      for (i = m = ref = y + 1, ref1 = y + len; ref <= ref1 ? m < ref1 : m > ref1; i = ref <= ref1 ? ++m : --m) {
        for (j = n = ref2 = i + 1, ref3 = y + len; ref2 <= ref3 ? n <= ref3 : n >= ref3; j = ref2 <= ref3 ? ++n : --n) {
          constraints.push([this.cells[i][x].string(), this.cells[j][x].string(), neq]);
        }
      }
      return constraints;
    };

    Kakuro.prototype.makeRowAddConstraints = function(x, y) {
      var allConstraints, c, constraints, domain, i, j, k, l, len, len1, len2, len3, m, n, o, perm, permutations, totalCell, v, valid, way, waysArr;
      totalCell = this.rowTotal(x, y);
      x = totalCell.x;
      y = totalCell.y;
      len = this.rowLength(x, y);
      waysArr = ways(totalCell.topRight(), len);
      if (waysArr.length === 1) {
        return {
          "domain": [0],
          "constraints": []
        };
      }
      allConstraints = [];
      domain = [];
      for (k = m = 0, len1 = waysArr.length; m < len1; k = ++m) {
        way = waysArr[k];
        permutations = permute(way);
        l = permutations.length;
        for (j = n = 0, len2 = permutations.length; n < len2; j = ++n) {
          perm = permutations[j];
          constraints = [];
          valid = true;
          for (i = o = 0, len3 = perm.length; o < len3; i = ++o) {
            v = perm[i];
            c = this.getCell(x + i + 1, y);
            if (c.domain.indexOf(v) === -1) {
              valid = false;
              break;
            }
            constraints.push([totalCell.string() + "r", c.string(), vals(k * l + j, v)]);
          }
          if (valid) {
            domain.push(k * l + j);
            allConstraints.push.apply(allConstraints, constraints);
          }
        }
      }
      return {
        "domain": domain,
        "constraints": allConstraints
      };
    };

    Kakuro.prototype.makeColAddConstraints = function(x, y) {
      var allConstraints, c, constraints, domain, i, j, k, l, len, len1, len2, len3, m, n, o, perm, permutations, totalCell, v, valid, way, waysArr;
      totalCell = this.colTotal(x, y);
      x = totalCell.x;
      y = totalCell.y;
      len = this.colLength(x, y);
      waysArr = ways(totalCell.bottomLeft(), len);
      if (waysArr.length === 1) {
        return {
          "domain": [0],
          "constraints": []
        };
      }
      allConstraints = [];
      domain = [];
      for (k = m = 0, len1 = waysArr.length; m < len1; k = ++m) {
        way = waysArr[k];
        permutations = permute(way);
        l = permutations.length;
        for (j = n = 0, len2 = permutations.length; n < len2; j = ++n) {
          perm = permutations[j];
          constraints = [];
          valid = true;
          for (i = o = 0, len3 = perm.length; o < len3; i = ++o) {
            v = perm[i];
            c = this.getCell(x, y + i + 1);
            if (c.domain.indexOf(v) === -1) {
              valid = false;
              break;
            }
            constraints.push([totalCell.string() + "c", c.string(), vals(k * l + j, v)]);
          }
          if (valid) {
            domain.push(k * l + j);
            allConstraints.push.apply(allConstraints, constraints);
          }
        }
      }
      return {
        "domain": domain,
        "constraints": allConstraints
      };
    };

    Kakuro.prototype.solveItr = function() {
      if (this.solveSingleDomain()) {
        this.renderOnPage();
        return true;
      }
      if (this.solveGraphSolvable()) {
        this.renderOnPage();
        return true;
      }
    };

    Kakuro.prototype.solveSingleDomain = function() {
      var cell, len1, len2, m, n, ref, row;
      ref = this.cells;
      for (m = 0, len1 = ref.length; m < len1; m++) {
        row = ref[m];
        for (n = 0, len2 = row.length; n < len2; n++) {
          cell = row[n];
          if (cell.isNumber()) {
            if (cell.domain.length === 1 && cell.raw === "") {
              this.insert(cell.x, cell.y, cell.domain[0]);
              return true;
            }
          }
        }
      }
      return false;
    };

    Kakuro.prototype.solveGraphSolvable = function() {
      var cell, len1, len2, m, n, ref, row;
      ref = this.cells;
      for (m = 0, len1 = ref.length; m < len1; m++) {
        row = ref[m];
        for (n = 0, len2 = row.length; n < len2; n++) {
          cell = row[n];
          if (cell.isNumber()) {
            if (cell.raw === "" && cell.graphSolvable !== this.totalNumbers()) {
              this.insertGraphSolvable(cell);
              return true;
            }
          }
        }
      }
      return false;
    };

    Kakuro.prototype.insertGraphSolvable = function(cell) {
      var constrains, start, total, totalsFound;
      constrains = cell.constrains;
      cell.constrains = [];
      total = 0;
      totalsFound = {};
      start = 2 * cell.graphSolvable < this.totalNumbers ? constrains[0] : constrains[constrains.length - 1];
      this.dfsMap(start, function(c) {
        var colTotal, rowTotal;
        rowTotal = c.rowTotal;
        colTotal = c.colTotal;
        if (c !== cell) {
          if (!totalsFound["r" + rowTotal.string()]) {
            totalsFound["r" + rowTotal.string()] = true;
            total += rowTotal.topRight();
          }
          if (!totalsFound["c" + colTotal.string()]) {
            totalsFound["c" + colTotal.string()] = true;
            return total -= colTotal.bottomLeft();
          }
        }
      });
      cell.constrains = constrains;
      this.insert(cell.x, cell.y, Math.abs(total));
      return true;
    };

    Kakuro.prototype.resetDiscovered = function() {
      return this.map(function(x) {
        return x.discovered = false;
      });
    };

    Kakuro.prototype.dfs = function(start) {
      var total;
      total = 0;
      this.dfsMap(start, function() {
        return total++;
      });
      return total;
    };

    Kakuro.prototype.dfsMap = function(start, f) {
      var len1, m, ref, stack, v, x;
      stack = [start];
      while (stack.length > 0) {
        v = stack.pop();
        if (v.discovered) {
          continue;
        }
        v.discovered = true;
        f(v);
        ref = v.constrains;
        for (m = 0, len1 = ref.length; m < len1; m++) {
          x = ref[m];
          stack.push(x);
        }
      }
      return this.resetDiscovered();
    };

    Kakuro.prototype.totalNumbers = function() {
      var total;
      if (this.totalNumbersCache != null) {
        return this.totalNumbersCache;
      }
      total = 0;
      this.map(function(x) {
        if (x.isNumber()) {
          return total++;
        }
      });
      return this.totalNumbersCache = total;
    };

    Kakuro.prototype.markGraphSolvable = function() {
      return this.map((function(_this) {
        return function(cell) {
          var constrains;
          if (cell.isNumber()) {
            constrains = cell.constrains;
            cell.constrains = [];
            cell.graphSolvable = _this.dfs(constrains[0]);
            return cell.constrains = constrains;
          }
        };
      })(this));
    };

    Kakuro.prototype.insert = function(x, y, val) {
      var cell, col, colTotal, colWays, idx, isIn, len1, len2, m, n, ref, ref1, results, row, rowTotal, rowWays;
      cell = this.getCell(x, y);
      console.assert(cell.domain.includes(val), "inserting into " + (cell.string()) + " value " + val + " but not in domain");
      cell.raw = "" + val;
      row = this.getRow(x, y);
      rowTotal = row[0].topRight();
      rowWays = waysIncludes.apply(null, [rowTotal, row.length - 1].concat(slice.call(this.rowInserted(x, y)))).reduce(function(a, b) {
        return a.concat(b);
      });
      col = this.getCol(x, y);
      colTotal = col[0].bottomLeft();
      colWays = waysIncludes.apply(null, [colTotal, col.length - 1].concat(slice.call(this.colInserted(x, y)))).reduce(function(a, b) {
        return a.concat(b);
      });
      ref = row.slice(1);
      for (m = 0, len1 = ref.length; m < len1; m++) {
        cell = ref[m];
        if (!((cell.x === x) && (cell.y === y))) {
          idx = cell.domain.indexOf(val);
          isIn = idx >= 0;
          if (isIn) {
            cell.domain.splice(cell.domain.indexOf(val), 1);
          }
          cell.domain = intersect(cell.domain, rowWays);
        }
      }
      ref1 = col.slice(1);
      results = [];
      for (n = 0, len2 = ref1.length; n < len2; n++) {
        cell = ref1[n];
        if (!((cell.x === x) && (cell.y === y))) {
          idx = cell.domain.indexOf(val);
          isIn = idx >= 0;
          if (isIn) {
            cell.domain.splice(cell.domain.indexOf(val), 1);
          }
          results.push(cell.domain = intersect(cell.domain, colWays));
        } else {
          results.push(void 0);
        }
      }
      return results;
    };

    Kakuro.prototype.getRow = function(x, y) {
      var i, m, ref, row, rowLength, rowTotal;
      rowTotal = this.rowTotal(x, y);
      x = rowTotal.x;
      y = rowTotal.y;
      rowLength = this.rowLength(x, y);
      row = [rowTotal];
      for (i = m = 1, ref = rowLength; 1 <= ref ? m <= ref : m >= ref; i = 1 <= ref ? ++m : --m) {
        row.push(this.getCell(x + i, y));
      }
      return row;
    };

    Kakuro.prototype.getCol = function(x, y) {
      var col, colLength, colTotal, i, m, ref;
      colTotal = this.colTotal(x, y);
      x = colTotal.x;
      y = colTotal.y;
      colLength = this.colLength(x, y);
      col = [colTotal];
      for (i = m = 1, ref = colLength; 1 <= ref ? m <= ref : m >= ref; i = 1 <= ref ? ++m : --m) {
        col.push(this.getCell(x, y + i));
      }
      return col;
    };

    Kakuro.prototype.rowInserted = function(x, y) {
      var cell, len1, m, ref, results;
      ref = this.getRow(x, y).slice(1);
      results = [];
      for (m = 0, len1 = ref.length; m < len1; m++) {
        cell = ref[m];
        if (cell.raw !== "") {
          results.push(cell.number());
        }
      }
      return results;
    };

    Kakuro.prototype.colInserted = function(x, y) {
      var cell, len1, m, ref, results;
      ref = this.getCol(x, y).slice(1);
      results = [];
      for (m = 0, len1 = ref.length; m < len1; m++) {
        cell = ref[m];
        if (cell.raw !== "") {
          results.push(cell.number());
        }
      }
      return results;
    };

    Kakuro.prototype.renderOnPage = function() {
      return $('#kakuro-container').html(this.toHtml());
    };

    return Kakuro;

  })();

  Cell = (function() {
    function Cell(text, x, y, domain) {
      this.raw = text;
      this.x = x;
      this.y = y;
      this.domain = domain;
      this.discovered = false;
    }

    Cell.prototype.type = function() {
      if (this.raw === 'x') {
        return 'BLANK';
      }
      if (this.raw.includes('-')) {
        return 'TOTAL';
      }
      return 'NUMBER';
    };

    Cell.prototype.render = function() {
      if (this.type() === 'BLANK') {
        return '<td class="blank"></td>';
      }
      if (this.type() === 'TOTAL') {
        return '<td class="total">' + '<table>' + '<tr>' + '<td>' + this.topRightStr() + '</td>' + '</tr>' + '<tr>' + '<td>' + this.bottomLeftStr() + '</td>' + '</tr>' + '</table>' + '</td>';
      }
      return '<td class="number">' + this.raw + '</td>';
    };

    Cell.prototype.topRight = function() {
      var s;
      s = parseInt(this.raw.split('-')[1]);
      if (!!s) {
        return parseInt(s);
      } else {
        return 0;
      }
    };

    Cell.prototype.bottomLeft = function() {
      var s;
      s = this.raw.split('-')[0];
      if (!!s) {
        return parseInt(s);
      } else {
        return 0;
      }
    };

    Cell.prototype.topRightStr = function() {
      if (this.topRight() === 0) {
        return "";
      } else {
        return this.topRight() + "&rarr;";
      }
    };

    Cell.prototype.bottomLeftStr = function() {
      if (this.bottomLeft() === 0) {
        return "";
      } else {
        return this.bottomLeft() + "&darr;";
      }
    };

    Cell.prototype.number = function() {
      return parseInt(this.raw);
    };

    Cell.prototype.string = function() {
      return "(" + this.x + "," + this.y + ")";
    };

    Cell.prototype.isTotal = function() {
      return this.type() === 'TOTAL';
    };

    Cell.prototype.isNumber = function() {
      return this.type() === 'NUMBER';
    };

    Cell.prototype.isColTotal = function() {
      return this.isTotal() && this.bottomLeft() !== 0;
    };

    Cell.prototype.isRowTotal = function() {
      return this.isTotal() && this.topRight() !== 0;
    };

    return Cell;

  })();

}).call(this);
