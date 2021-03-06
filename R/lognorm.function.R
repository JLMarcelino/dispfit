lognorm.function <- function (data, chi.res.hist, ks.res.hist) {
log.dist.lognorm <- function (par, r) {
  a <- par[1]
  b <- par[2]
  flognorm <- (1 / (((2 * pi) ^ (3/2)) * (b * (r ^ 2)))) * exp(-(log(r / a)^2) / (2 * (b ^ 2)))
  -sum(log(flognorm)) ## Negative Log Likelihood da lognormiana
}
dist.lognorm <- function (r, a, b) {
  flognorm <- 2*pi*r * (1 / (((2 * pi) ^ (3/2)) * (b * (r ^ 2)))) * exp(-(log(r / a)^2) / (2 * (b ^ 2)))
}
# initial values estimation
n <- length(data)
lx <- log(data)
sd0 <- sqrt((n - 1)/n) * sd(lx)
ml <- mean(lx)
# optimization procedure
dist.lognorm.opt <- optim (par = c(ml, sd0), ## valor inicial para o "a"
                           fn = log.dist.lognorm, ## função a minimizar
                           r = data,
                           method = "Nelder-Mead")
# output values
# AIC
aic.lognorm <- 2 * length(dist.lognorm.opt$par) + 2 * dist.lognorm.opt$value
# AICc
aicc.lognorm <- aic.lognorm + (2 * length(dist.lognorm.opt$par)^2 + 2 * length(dist.lognorm.opt$par))/(length(data) - length(dist.lognorm.opt$par) - 1 )
# BIC
bic.lognorm <-  2 * dist.lognorm.opt$value + length(dist.lognorm.opt$par)*log(length(data))
# Chi-squared
chi.expected.values.lognorm <- dist.lognorm(chi.res.hist$mids, dist.lognorm.opt$par[1], dist.lognorm.opt$par[2])*length(data)*(chi.res.hist$breaks[2] - chi.res.hist$breaks[1])
chi.squared.statistic.lognorm <- sum((chi.res.hist$counts - chi.expected.values.lognorm)^2 / chi.expected.values.lognorm)
chi.squared.pvalue.lognorm <- 1-pchisq(chi.squared.statistic.lognorm, length(chi.res.hist$counts)-3)
# Kolmogorov-Smirnov
ks.expected.values.lognorm <- dist.lognorm(ks.res.hist$mids, dist.lognorm.opt$par[1], dist.lognorm.opt$par[2])*length(data)*(ks.res.hist$breaks[2] - ks.res.hist$breaks[1])
simul.lognorm <- c()
for (i in seq_along(ks.res.hist$mids)) {
  simul.lognorm <- c(simul.lognorm, rep(ks.res.hist$mids[i], round(ks.expected.values.lognorm[i], 0)))
}
ks.lognorm <- ks.test(data, simul.lognorm)
g.max.lognorm <- as.numeric(ks.lognorm$statistic)
KS.lognorm <- as.numeric(ks.lognorm$p.value)

# cumulative.expected.values.lognorm <- c(expected.values.lognorm[1])
# for (i in 1+seq_along(expected.values.lognorm)) {
#   cumulative.expected.values.lognorm[i] <- cumulative.expected.values.lognorm[i-1] + expected.values.lognorm[i]
# }
# cumulative.expected.values.lognorm <- cumulative.expected.values.lognorm/sum(expected.values.lognorm)
# cumulative.expected.values.lognorm <- cumulative.expected.values.lognorm[!is.na(cumulative.expected.values.lognorm)]
# g.max.lognorm <- max(abs(cumulative.data - cumulative.expected.values.lognorm))
# if (g.max.lognorm < (sqrt(-log(0.01/2)/(2*length(cumulative.data))) * (1/(2*length(cumulative.data))))) {
#   KS.lognorm <- "Accept"
# } else {KS.lognorm <- "Reject"}
# parameter estimate
par.1.lognorm <- dist.lognorm.opt$par[1]
par.2.lognorm <- dist.lognorm.opt$par[2]
# parameter estimate standard error
par.1.se.lognorm <- sqrt(diag(solve(numDeriv::hessian(log.dist.lognorm, x=dist.lognorm.opt$par, r=data))))[1]
par.2.se.lognorm <- sqrt(diag(solve(numDeriv::hessian(log.dist.lognorm, x=dist.lognorm.opt$par, r=data))))[2]
# mean dispersal distance
mean.lognorm <- dist.lognorm.opt$par[1] * exp((dist.lognorm.opt$par[2]^2)/2)
mean.stderr.lognorm <- msm::deltamethod(~ x1 * exp((x2^2)/2), mean = dist.lognorm.opt$par, cov = solve(numDeriv::hessian(log.dist.lognorm, x=dist.lognorm.opt$par, r=data)) )
# variance
variance.lognorm <- (exp(dist.lognorm.opt$par[2]^2)-1) * dist.lognorm.opt$par[1]^2 * exp(dist.lognorm.opt$par[2]^2)
variance.stderr.lognorm <- msm::deltamethod(~ (exp(x2^2)-1) * x1^2 * exp(x2^2), mean = dist.lognorm.opt$par, cov = solve(numDeriv::hessian(log.dist.lognorm, x=dist.lognorm.opt$par, r=data)))
# skewness
skewness.lognorm <- (exp(dist.lognorm.opt$par[2]^2)+2) * sqrt(exp(dist.lognorm.opt$par[2]^2)-1)
skewness.stderr.lognorm <- msm::deltamethod(~ (exp(x2^2)+2) * sqrt(exp(x2^2)-1), mean = dist.lognorm.opt$par, cov = solve(numDeriv::hessian(log.dist.lognorm, x=dist.lognorm.opt$par, r=data)) )
# kurtosis
kurtosis.lognorm <- exp(4*dist.lognorm.opt$par[2]^2) + 2*exp(3*dist.lognorm.opt$par[2]^2) + 3*exp(2*dist.lognorm.opt$par[2]^2) - 6
kurtosis.stderr.lognorm <- msm::deltamethod(~ exp(4*x2^2) + 2*exp(3*x2^2) + 3*exp(2*x2^2) - 6, mean = dist.lognorm.opt$par, cov = solve(numDeriv::hessian(log.dist.lognorm, x=dist.lognorm.opt$par, r=data)) )
# output
res <- data.frame(aic.lognorm, aicc.lognorm, bic.lognorm,
                             chi.squared.statistic.lognorm, chi.squared.pvalue.lognorm,g.max.lognorm, KS.lognorm,
                             par.1.lognorm, par.1.se.lognorm, par.2.lognorm, par.2.se.lognorm,
                             mean.lognorm, mean.stderr.lognorm, variance.lognorm, variance.stderr.lognorm,
                             skewness.lognorm, skewness.stderr.lognorm, kurtosis.lognorm, kurtosis.stderr.lognorm)
lognorm.values <- list("opt" = dist.lognorm.opt, "res" = res)
}
