const fs = require('fs');
const json = JSON.parse(fs.readFileSync('./swagger-output.json', 'utf8'));
const paths = json.paths || {};

let summary = [];

Object.keys(paths).forEach(path => {
  const methods = paths[path];
  Object.keys(methods).forEach(method => {
    const details = methods[method];
    summary.push(`- **${method.toUpperCase()}** \`${path}\` - ${details.summary || ''}`);
  });
});

fs.writeFileSync('./API_SUMMARY.md', summary.join('\n'), 'utf8');
console.log('Done');
