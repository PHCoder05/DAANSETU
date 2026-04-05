const fs = require('fs');

const json = JSON.parse(fs.readFileSync('./swagger-output.json', 'utf8'));

let md = `# ${json.info.title} (v${json.info.version})\n\n`;
md += `${json.info.description}\n\n`;

const paths = json.paths || {};

Object.keys(paths).forEach(path => {
  const methods = paths[path];
  Object.keys(methods).forEach(method => {
    const details = methods[method];
    md += `## \`${method.toUpperCase()}\` ${path}\n\n`;
    if (details.summary) md += `**Summary**: ${details.summary}\n\n`;
    if (details.description) md += `**Description**: ${details.description}\n\n`;
    if (details.tags && details.tags.length > 0) md += `**Tags**: ${details.tags.join(', ')}\n\n`;
    if (details.security && details.security.length > 0) md += `**Security**: ${JSON.stringify(details.security)}\n\n`;
    
    if (details.parameters && details.parameters.length > 0) {
      md += `### Parameters\n`;
      md += `| Name | In | Required | Type | Description |\n`;
      md += `| --- | --- | --- | --- | --- |\n`;
      details.parameters.forEach(p => {
        md += `| ${p.name || ''} | ${p.in || ''} | ${p.required ? 'Yes' : 'No'} | ${p.schema ? p.schema.type : ''} | ${p.description || ''} |\n`;
      });
      md += `\n`;
    }

    if (details.responses) {
      md += `### Responses\n`;
      md += `| Code | Description |\n`;
      md += `| --- | --- |\n`;
      Object.keys(details.responses).forEach(code => {
        md += `| ${code} | ${details.responses[code].description || ''} |\n`;
      });
      md += `\n`;
    }
  });
});

fs.writeFileSync('./API_DOCS.md', md, 'utf8');
console.log('Markdown generated at API_DOCS.md');
